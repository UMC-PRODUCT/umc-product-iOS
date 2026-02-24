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

    private enum Constants {
        static let myStudyGroupsPageSize = 100
    }

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
            return []
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
        if isSchoolCoreRole {
            if let groups = try await fetchStudyGroupsByNames() {
                return groups
            }
        } else if let groups = try await fetchMyStudyGroups() {
            return groups
        }

        return try await fallbackRepository.fetchStudyGroups()
    }

    func fetchStudyGroupDetails() async throws -> [StudyGroupInfo] {
        let groups = try await fetchStudyGroups()
            .filter { $0 != .all }

        if groups.isEmpty {
            return []
        }

        var detailDTOs: [(groupName: String, dto: StudyGroupDetailDTO)] = []
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

                detailDTOs.append((groupName: group.name, dto: dto))
            } catch {
                continue
            }
        }

        if detailDTOs.isEmpty {
            return []
        }

        let memberIDs = Array(
            Set(
                detailDTOs.flatMap { item in
                    [item.dto.leader.memberId] + item.dto.members.map(\.memberId)
                }
            )
        )
        let bestWorkbookPointByMemberID = await fetchBestWorkbookPoints(
            memberIDs: memberIDs
        )

        let details = detailDTOs.map { item in
            item.dto.toDomain(
                defaultGroupName: item.groupName,
                bestWorkbookPointByMemberID: bestWorkbookPointByMemberID
            )
        }

        if details.isEmpty {
            return []
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

    func createStudyGroupSchedule(
        name: String,
        startsAt: Date,
        endsAt: Date,
        isAllDay: Bool,
        locationName: String,
        latitude: Double,
        longitude: Double,
        description: String,
        studyGroupId: Int,
        gisuId: Int,
        requiresApproval: Bool
    ) async throws {
        let response = try await adapter.request(
            StudyRouter.createStudyGroupSchedule(
                body: StudyGroupScheduleCreateRequestDTO(
                    name: name,
                    startsAt: startsAt,
                    endsAt: endsAt,
                    isAllDay: isAllDay,
                    locationName: locationName,
                    latitude: latitude,
                    longitude: longitude,
                    description: description,
                    tags: ["STUDY"],
                    studyGroupId: studyGroupId,
                    gisuId: gisuId,
                    requiresApproval: requiresApproval
                )
            )
        )

        let apiResponse = try decoder.decode(
            APIResponse<String>.self,
            from: response.data
        )
        try apiResponse.validateSuccess()
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

        do {
            let apiResponse = try decoder.decode(
                APIResponse<EmptyResult>.self,
                from: response.data
            )
            try apiResponse.validateSuccess()
        } catch let repositoryError as RepositoryError {
            throw repositoryError
        } catch {
            throw RepositoryError.decodingError(
                detail: error.localizedDescription
            )
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

    /// 회장단(교내 회장/부회장) 권한 여부
    private var isSchoolCoreRole: Bool {
        let defaults = UserDefaults.standard
        let roleRawValue = defaults.string(forKey: AppStorageKey.memberRole) ?? ""
        guard let role = ManagementTeam(rawValue: roleRawValue) else {
            return false
        }
        return role == .schoolPresident || role == .schoolVicePresident
    }

    /// 교내 회장단 전용 전체 그룹 목록 조회 (`/study-groups/names`)
    private func fetchStudyGroupsByNames() async throws -> [StudyGroupItem]? {
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

        return nil
    }

    /// 회장단 외 사용자 전용 그룹 목록 조회 (`/study-groups`, cursor 기반)
    private func fetchMyStudyGroups() async throws -> [StudyGroupItem]? {
        var cursor: Int? = nil
        var hasNext = true
        var aggregated: [StudyGroupNameItemDTO] = []

        while hasNext {
            let response = try await adapter.request(
                StudyRouter.getMyStudyGroups(
                    cursor: cursor,
                    size: Constants.myStudyGroupsPageSize
                )
            )

            let page: MyStudyGroupsPageDTO
            if let apiResponse = try? decoder.decode(
                APIResponse<MyStudyGroupsPageDTO>.self,
                from: response.data
            ),
               let wrapped = try? apiResponse.unwrap() {
                page = wrapped
            } else if let plain = try? decoder.decode(
                MyStudyGroupsPageDTO.self,
                from: response.data
            ) {
                page = plain
            } else {
                return nil
            }

            aggregated.append(contentsOf: page.studyGroups)
            hasNext = page.hasNext
            cursor = page.nextCursor
            if hasNext && cursor == nil {
                break
            }
        }

        guard !aggregated.isEmpty else {
            return [.all]
        }

        var deduplicatedByGroupID: [Int: StudyGroupNameItemDTO] = [:]
        aggregated.forEach { item in
            deduplicatedByGroupID[item.groupId] = item
        }

        let sortedItems = deduplicatedByGroupID.values.sorted { lhs, rhs in
            lhs.groupId < rhs.groupId
        }

        return [.all] + sortedItems.map { item in
            StudyGroupItem(
                serverID: String(item.groupId),
                name: item.name,
                iconName: "person.2.fill",
                part: nil
            )
        }
    }

    /// 멤버별 베스트 워크북 점수 조회 (`/member/profile/{memberId}`)
    private func fetchBestWorkbookPoints(
        memberIDs: [Int]
    ) async -> [Int: Int] {
        var result: [Int: Int] = [:]

        await withTaskGroup(of: (Int, Int)?.self) { group in
            for memberID in Set(memberIDs) {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    let point = await self.fetchBestWorkbookPoint(memberID: memberID)
                    return (memberID, point)
                }
            }

            for await item in group {
                guard let item else { continue }
                result[item.0] = item.1
            }
        }

        return result
    }

    /// 단일 멤버 베스트 워크북 점수 조회
    private func fetchBestWorkbookPoint(memberID: Int) async -> Int {
        do {
            let response = try await adapter.request(
                StudyRouter.getMemberProfile(memberId: memberID)
            )

            if let apiResponse = try? decoder.decode(
                APIResponse<MemberProfileBestWorkbookDTO>.self,
                from: response.data
            ),
               let wrapped = try? apiResponse.unwrap() {
                return wrapped.bestWorkbookDisplayPoint
            }

            if let plain = try? decoder.decode(
                MemberProfileBestWorkbookDTO.self,
                from: response.data
            ) {
                return plain.bestWorkbookDisplayPoint
            }
        } catch {
            // 포인트 조회 실패는 그룹 상세 표시를 막지 않도록 0점 처리
        }

        return 0
    }

    /// UserDefaults에 저장된 담당 파트를 API 요청에 사용할 값으로 변환합니다.
    ///
    /// 알 수 없는 파트 값은 "IOS"로 fallback 처리합니다.
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

    /// 서버 오류 응답에서 도메인/리포지토리 에러를 파싱합니다.
    ///
    /// HTTP 상태 코드와 서버 에러 코드/메시지를 분석하여 적절한 에러 타입으로 변환합니다.
    /// - Parameter error: 네트워크 계층에서 발생한 `NetworkError`
    /// - Returns: 변환된 도메인/리포지토리 에러, 변환 불가 시 nil
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
