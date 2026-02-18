//
//  StudyRepository.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation
import Moya

/// Study Repository 실제 API 구현체
final class StudyRepository: StudyRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder
    private let fallbackRepository: StudyRepositoryProtocol

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder(),
        fallbackRepository: StudyRepositoryProtocol = MockStudyRepository()
    ) {
        self.adapter = adapter
        self.decoder = decoder
        self.fallbackRepository = fallbackRepository
    }

    // MARK: - Curriculum

    func fetchCurriculumData() async throws -> CurriculumData {
        let progressResponse = try await adapter.request(StudyRouter.getMyProgress)
        let progressAPIResponse = try decoder.decode(
            APIResponse<ChallengerCurriculumProgressDTO>.self,
            from: progressResponse.data
        )
        let progressDTO = try progressAPIResponse.unwrap()

        let scheduleByWeek: [Int: WorkbookSchedule]
        do {
            let curriculumResponse = try await adapter.request(
                StudyRouter.getCurriculum(part: progressDTO.part)
            )
            let curriculumAPIResponse = try decoder.decode(
                APIResponse<CurriculumDTO>.self,
                from: curriculumResponse.data
            )
            scheduleByWeek = try curriculumAPIResponse.unwrap().scheduleByWeek
        } catch {
            // 진행 상황 API만으로도 화면은 구성 가능하도록 보조 API 실패는 폴백 처리
            scheduleByWeek = [:]
        }

        return progressDTO.toDomain(scheduleByWeek: scheduleByWeek)
    }

    func fetchCurriculumProgress() async throws -> CurriculumProgressModel {
        try await fetchCurriculumData().progress
    }

    func fetchMissions() async throws -> [MissionCardModel] {
        try await fetchCurriculumData().missions
    }

    // MARK: - Submission

    func submitMission(
        missionId: Int,
        type: MissionSubmissionType,
        link: String?
    ) async throws {
        let submissionPayload: String
        switch type {
        case .link:
            guard let link, !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DomainError.missionLinkRequired
            }
            submissionPayload = link
        case .completeOnly:
            submissionPayload = "COMPLETED"
        }

        do {
            let response = try await adapter.request(
                StudyRouter.submitWorkbook(
                    challengerWorkbookId: missionId,
                    body: WorkbookSubmissionRequestDTO(submission: submissionPayload)
                )
            )
            let apiResponse = try decoder.decode(
                APIResponse<EmptyResult>.self,
                from: response.data
            )
            try apiResponse.validateSuccess()
        } catch let error as NetworkError {
            throw Self.parseSubmissionError(from: error) ?? error
        }
    }

    // MARK: - 운영진 스터디 관리 (Fallback)

    func fetchStudyMembers() async throws -> [StudyMemberItem] {
        try await fallbackRepository.fetchStudyMembers()
    }

    func fetchStudyGroups() async throws -> [StudyGroupItem] {
        try await fallbackRepository.fetchStudyGroups()
    }

    func fetchWeeks() async throws -> [Int] {
        let part = resolvedPartAPIValue
        let response = try await adapter.request(
            StudyRouter.getCurriculumWeeks(part: part)
        )
        let apiResponse = try decoder.decode(
            APIResponse<CurriculumWeeksDTO>.self,
            from: response.data
        )
        let weeks = try apiResponse.unwrap()
            .weeks
            .compactMap { Int($0.weekNo) }
            .sorted()

        if weeks.isEmpty {
            return try await fallbackRepository.fetchWeeks()
        }
        return weeks
    }

    // MARK: - Private Helper

    private var resolvedPartAPIValue: String {
        let defaults = UserDefaults.standard
        let storedPart = defaults.string(forKey: AppStorageKey.responsiblePart) ?? "IOS"
        switch storedPart.uppercased() {
        case "PLAN", "DESIGN", "WEB", "ANDROID", "IOS", "NODEJS", "SPRINGBOOT":
            return storedPart.uppercased()
        default:
            return "IOS"
        }
    }

    private static func parseSubmissionError(
        from error: NetworkError
    ) -> Error? {
        guard case .requestFailed(let statusCode, let data) = error,
              let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let code = json["code"] as? String
        let rawMessage = (json["message"] as? String) ?? (json["result"] as? String) ?? ""
        if statusCode == 404 || code == "CURRICULUM-0006" {
            return DomainError.missionNotFound
        }
        if statusCode == 400,
           (rawMessage.contains("PENDING") || rawMessage.contains("유효하지 않음")) {
            return DomainError.workbookAlreadySubmitted
        }
        if rawMessage.contains("이미 제출") {
            return DomainError.workbookAlreadySubmitted
        }
        if rawMessage.contains("기한") {
            return DomainError.workbookDeadlinePassed
        }
        if !rawMessage.isEmpty {
            return RepositoryError.serverError(
                code: code,
                message: rawMessage
            )
        }
        return nil
    }
}
