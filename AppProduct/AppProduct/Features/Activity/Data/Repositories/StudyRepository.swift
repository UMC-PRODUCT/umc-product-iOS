//
//  StudyRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
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

    func fetchStudyMembers(
        week: Int,
        studyGroupId: Int?
    ) async throws -> [StudyMemberItem] {
        if let studyGroupId {
            return try await fetchMembersByGroup(
                week: week,
                studyGroupId: studyGroupId
            )
        }

        let groups = try await fetchStudyGroups()
            .filter { $0 != .all }
            .compactMap { Int($0.serverID) }
        if groups.isEmpty {
            return try await fallbackRepository.fetchStudyMembers(
                week: week,
                studyGroupId: nil
            )
        }

        var merged: [StudyMemberItem] = []
        for groupId in groups {
            let members = try await fetchMembersByGroup(
                week: week,
                studyGroupId: groupId
            )
            merged.append(contentsOf: members)
        }

        // 중복 제거 (같은 챌린저가 여러 그룹에 걸쳐 중복 노출되는 경우 방지)
        var deduplicated: [String: StudyMemberItem] = [:]
        merged.forEach { deduplicated[$0.serverID] = $0 }
        return Array(deduplicated.values)
            .sorted { $0.displayName < $1.displayName }
    }

    func fetchStudyGroups() async throws -> [StudyGroupItem] {
        let response = try await adapter.request(StudyRouter.getStudyGroupNames)

        // 서버별 응답 포맷 차이를 흡수합니다.
        if let apiResponse = try? decoder.decode(
            APIResponse<StudyGroupNamesDTO>.self,
            from: response.data
        ),
           let wrapped = try? apiResponse.unwrap() {
            return wrapped.toDomain()
        }

        if let plain = try? decoder.decode(
            StudyGroupNamesDTO.self,
            from: response.data
        ) {
            return plain.toDomain()
        }

        return try await fallbackRepository.fetchStudyGroups()
    }

    func fetchStudyGroupDetails() async throws -> [StudyGroupInfo] {
        let groups = try await fetchStudyGroups()
            .filter { $0 != .all }

        if groups.isEmpty {
            return try await fallbackRepository.fetchStudyGroupDetails()
        }

        var details: [StudyGroupInfo] = []
        for group in groups {
            guard let groupId = Int(group.serverID) else { continue }

            do {
                let response = try await adapter.request(
                    StudyRouter.getStudyGroupDetail(groupId: groupId)
                )

                let dto: StudyGroupDetailDTO
                if let apiResponse = try? decoder.decode(
                    APIResponse<StudyGroupDetailDTO>.self,
                    from: response.data
                ),
                   let wrapped = try? apiResponse.unwrap() {
                    dto = wrapped
                } else {
                    dto = try decoder.decode(
                        StudyGroupDetailDTO.self,
                        from: response.data
                    )
                }

                details.append(
                    dto.toDomain(defaultGroupName: group.name)
                )
            } catch {
                continue
            }
        }

        if details.isEmpty {
            return try await fallbackRepository.fetchStudyGroupDetails()
        }
        return details
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

    func fetchWorkbookSubmissionURL(
        challengerWorkbookId: Int
    ) async throws -> String? {
        let response = try await adapter.request(
            StudyRouter.getWorkbookSubmission(
                challengerWorkbookId: challengerWorkbookId
            )
        )

        let dto: WorkbookSubmissionDetailDTO
        if let apiResponse = try? decoder.decode(
            APIResponse<WorkbookSubmissionDetailDTO>.self,
            from: response.data
        ),
           let wrapped = try? apiResponse.unwrap() {
            dto = wrapped
        } else {
            dto = try decoder.decode(
                WorkbookSubmissionDetailDTO.self,
                from: response.data
            )
        }

        guard let submission = dto.submission,
              !submission.isEmpty else {
            return nil
        }
        return submission
    }

    func reviewWorkbook(
        challengerWorkbookId: Int,
        isApproved: Bool,
        feedback: String
    ) async throws {
        let status = isApproved ? "PASS" : "FAIL"
        let response = try await adapter.request(
            StudyRouter.reviewWorkbook(
                challengerWorkbookId: challengerWorkbookId,
                body: WorkbookReviewRequestDTO(
                    status: status,
                    feedback: feedback
                )
            )
        )

        if response.data.isEmpty {
            return
        }
        if let apiResponse = try? decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        ) {
            try apiResponse.validateSuccess()
        }
    }

    func selectBestWorkbook(
        challengerWorkbookId: Int,
        bestReason: String
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.selectBestWorkbook(
                challengerWorkbookId: challengerWorkbookId,
                body: BestWorkbookSelectionRequestDTO(bestReason: bestReason)
            )
        )

        if response.data.isEmpty {
            return
        }
        if let apiResponse = try? decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        ) {
            try apiResponse.validateSuccess()
        }
    }

    func createStudyGroup(
        name: String,
        part: UMCPartType,
        leaderId: Int,
        memberIds: [Int]
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.createStudyGroup(
                body: StudyGroupCreateRequestDTO(
                    name: name,
                    part: part.apiValue,
                    leaderId: leaderId,
                    memberIds: memberIds
                )
            )
        )

        if response.data.isEmpty {
            return
        }

        if let apiResponse = try? decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        ) {
            try apiResponse.validateSuccess()
            return
        }

        if let apiResponse = try? decoder.decode(
            APIResponse<StudyGroupDetailDTO>.self,
            from: response.data
        ),
           let _ = try? apiResponse.unwrap() {
            return
        }
    }

    func updateStudyGroup(
        groupId: Int,
        name: String,
        part: UMCPartType
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.updateStudyGroup(
                groupId: groupId,
                body: StudyGroupUpdateRequestDTO(
                    name: name,
                    part: part.apiValue
                )
            )
        )

        if response.data.isEmpty {
            return
        }

        if let apiResponse = try? decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        ) {
            try apiResponse.validateSuccess()
            return
        }

        if let apiResponse = try? decoder.decode(
            APIResponse<StudyGroupDetailDTO>.self,
            from: response.data
        ),
           let _ = try? apiResponse.unwrap() {
            return
        }
    }

    func deleteStudyGroup(
        groupId: Int
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.deleteStudyGroup(
                groupId: groupId
            )
        )

        if response.data.isEmpty {
            return
        }

        if let apiResponse = try? decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        ) {
            try apiResponse.validateSuccess()
        }
    }

    // MARK: - Private Helper

    private func fetchMembersByGroup(
        week: Int,
        studyGroupId: Int
    ) async throws -> [StudyMemberItem] {
        var cursor: Int? = nil
        var hasNext = true
        var members: [StudyMemberItem] = []

        while hasNext {
            let response = try await adapter.request(
                StudyRouter.getWorkbookSubmissions(
                    weekNo: week,
                    studyGroupId: studyGroupId,
                    cursor: cursor,
                    size: 100
                )
            )
            let page: WorkbookSubmissionPageDTO
            if let apiResponse = try? decoder.decode(
                APIResponse<WorkbookSubmissionPageDTO>.self,
                from: response.data
            ),
               let wrapped = try? apiResponse.unwrap() {
                page = wrapped
            } else {
                page = try decoder.decode(
                    WorkbookSubmissionPageDTO.self,
                    from: response.data
                )
            }

            members.append(contentsOf: page.content.map { $0.toDomain(week: week) })
            hasNext = page.hasNext
            cursor = page.nextCursor
        }
        return members
    }

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
