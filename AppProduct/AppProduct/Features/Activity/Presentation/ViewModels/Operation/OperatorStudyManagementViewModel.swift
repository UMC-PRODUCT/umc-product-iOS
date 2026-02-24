//
//  OperatorStudyManagementViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

/// 스터디 관리 화면의 상태를 관리하는 ViewModel
///
/// 제출 현황 조회, 스터디 그룹 CRUD, 리뷰/베스트 워크북 선정을 처리합니다.
@Observable
final class OperatorStudyManagementViewModel {
    // MARK: - Property

    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var useCase: FetchStudyMembersUseCaseProtocol

    /// 스터디원 목록 로딩 상태
    private(set) var membersState: Loadable<[StudyMemberItem]> = .idle

    /// 스터디 그룹 관리 로딩 상태
    private(set) var studyGroupDetailsState: Loadable<[StudyGroupInfo]> = .idle

    /// 스터디 그룹 필터 목록
    private(set) var studyGroups: [StudyGroupItem] = [.all]

    /// 현재 선택된 스터디 그룹 필터
    var selectedStudyGroup: StudyGroupItem = .all

    /// 주차 목록
    private(set) var weeks: [Int] = []

    /// 현재 선택된 주차
    var selectedWeek: Int = 1

    /// 스터디 그룹 관리 상태
    private(set) var studyGroupDetails: [StudyGroupInfo] = []

    /// 편집 중인 그룹 (시트 표시용)
    var editingGroup: StudyGroupInfo?

    /// 멤버 추가 대상 그룹 (시트 표시용)
    var addMemberGroup: StudyGroupInfo?

    /// 시트에서 선택된 챌린저 목록
    var selectedChallengers: [ChallengerInfo] = []

    /// 시트 표시 상태
    var selectedMemberForReview: StudyMemberItem?

    /// 베스트 워크북 선정 대상 멤버
    var selectedMemberForBest: StudyMemberItem?

    /// 확인 다이얼로그
    var alertPrompt: AlertPrompt?

    /// 시트 dismiss 후 표시할 대기 중인 AlertPrompt
    private var pendingAlertPrompt: AlertPrompt?

    /// 필터링 전 전체 멤버 목록
    private var allMembers: [StudyMemberItem] = []

    /// 그룹 상세 목록 최초 로드 여부
    private var hasLoadedStudyGroupDetails = false

    /// 제출 현황 탭 필터(그룹/주차) 최초 로드 여부
    private var hasLoadedSubmissionFilters = false

    #if DEBUG
    /// Activity Debug 스킴 시뮬레이션 모드
    private var isDebugSeedMode = false
    #endif

    // MARK: - Initializer

    /// - Parameters:
    ///   - container: 의존성 주입 컨테이너
    ///   - errorHandler: 전역 에러 핸들러
    ///   - useCase: 스터디 멤버 조회 UseCase
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        useCase: FetchStudyMembersUseCaseProtocol
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.useCase = useCase

        #if DEBUG
        self.studyGroupDetails = StudyGroupPreviewData.groups
        #endif
    }

    // MARK: - Function

    /// 스터디 멤버(제출 현황) 조회
    @MainActor
    func fetchMembers() async {
        await fetchSubmissionMembers()
    }

    /// 제출 현황 탭 진입/필터 변경 시 호출
    @MainActor
    func fetchSubmissionMembers() async {
        membersState = .loading

        #if DEBUG
        if isDebugSeedMode {
            if allMembers.isEmpty {
                allMembers = ActivityDebugState.studyMembersByCurrentWeek
            }

            if !hasLoadedSubmissionFilters {
                if studyGroups == [.all] {
                    studyGroups = normalizeStudyGroups(StudyGroupItem.preview)
                }
                weeks = Array(1...10)
                if !weeks.contains(selectedWeek), let firstWeek = weeks.first {
                    selectedWeek = firstWeek
                }
                hasLoadedSubmissionFilters = true
            }

            filterMembers()
            return
        }
        #endif

        do {
            if !hasLoadedSubmissionFilters {
                let fetchedGroups = try await useCase.fetchStudyGroups()
                studyGroups = normalizeStudyGroups(fetchedGroups)
                weeks = try await useCase.fetchWeeks()
                if !weeks.contains(selectedWeek), let firstWeek = weeks.first {
                    selectedWeek = firstWeek
                }
                hasLoadedSubmissionFilters = true
            }

            let selectedGroupId = selectedStudyGroup == .all
            ? nil
            : Int(selectedStudyGroup.serverID)
            let members = try await useCase.fetchMembers(
                week: selectedWeek,
                studyGroupId: selectedGroupId
            )
            allMembers = members
            filterMembers()
        } catch let error as DomainError {
            membersState = .failed(.domain(error))
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchStudyMembers",
                retryAction: { [weak self] in
                    await self?.fetchSubmissionMembers()
                }
            ))
        }
    }

    /// 스터디 그룹 관리 탭 진입 시 그룹 목록 및 상세 조회
    @MainActor
    func fetchGroupManagementData() async {
        if hasLoadedStudyGroupDetails {
            return
        }

        studyGroupDetailsState = .loading

        do {
            if studyGroups == [.all] {
                let fetchedGroups = try await useCase.fetchStudyGroups()
                studyGroups = normalizeStudyGroups(fetchedGroups)
            }

            let groupDetails = try await useCase.fetchStudyGroupDetails()
            studyGroupDetails = groupDetails
            studyGroupDetailsState = .loaded(groupDetails)
            hasLoadedStudyGroupDetails = true
        } catch let error as DomainError {
            studyGroupDetailsState = .failed(.domain(error))
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchStudyGroupManagement",
                retryAction: { [weak self] in
                    await self?.fetchGroupManagementData()
                }
            ))
            studyGroupDetailsState = .failed(.unknown(
                message: "스터디 그룹 관리 데이터를 불러오지 못했습니다."
            ))
        }
    }

    /// Sheet dismiss 시 호출 — ChallengerInfo → StudyGroupMember 변환
    func applySelectedChallengers() {
        guard let targetGroup = addMemberGroup,
              let index = studyGroupDetails.firstIndex(
                  where: { $0.id == targetGroup.id }
              )
        else {
            selectedChallengers = []
            return
        }

        let existingIDs = Set(
            studyGroupDetails[index].members.map(\.serverID)
        )
        let newMembers = selectedChallengers
            .map { challenger in
                StudyGroupMember(
                    serverID: String(challenger.memberId),
                    name: challenger.name,
                    nickname: challenger.nickname,
                    university: challenger.schoolName,
                    profileImageURL: challenger.profileImage
                )
            }
            .filter { !existingIDs.contains($0.serverID) }
        studyGroupDetails[index].members.append(
            contentsOf: newMembers
        )
        selectedChallengers = []
    }

    /// 그룹 정보(이름, 파트) 수정 적용
    /// - Parameters:
    ///   - groupID: 수정할 그룹 ID
    ///   - name: 새 그룹명
    ///   - part: 새 파트
    @MainActor
    func updateGroup(
        groupID: UUID,
        name: String,
        part: UMCPartType
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            alertPrompt = AlertPrompt(
                title: "수정 실패",
                message: "그룹 이름을 입력해 주세요.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        guard let oldGroup = studyGroupDetails.first(where: { $0.id == groupID }) else {
            alertPrompt = AlertPrompt(
                title: "수정 실패",
                message: "그룹 정보를 찾을 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        guard let serverGroupId = Int(oldGroup.serverID) else {
            alertPrompt = AlertPrompt(
                title: "수정 실패",
                message: "유효한 그룹 식별자가 아닙니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        do {
            try await useCase.updateStudyGroup(
                groupId: serverGroupId,
                name: trimmedName,
                part: part
            )
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "수정 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "updateStudyGroup"
            ))
            return false
        }

        guard let index = studyGroupDetails.firstIndex(where: { $0.id == groupID }) else {
            alertPrompt = AlertPrompt(
                title: "수정 실패",
                message: "그룹이 삭제되어 수정할 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        let old = studyGroupDetails[index]
        studyGroupDetails[index] = StudyGroupInfo(
            id: old.id,
            serverID: old.serverID,
            name: trimmedName,
            part: part,
            createdDate: old.createdDate,
            leader: old.leader,
            members: old.members
        )
        return true
    }

    /// 그룹 편집 시트 표시
    func showEditSheet(for group: StudyGroupInfo) {
        editingGroup = group
    }

    /// 멤버 추가 시트 표시
    func showAddMemberSheet(for group: StudyGroupInfo) {
        addMemberGroup = group
    }

    /// 새 스터디 그룹 생성 (ChallengerInfo → StudyGroupMember 변환)
    /// - Parameters:
    ///   - name: 그룹명
    ///   - part: 파트
    ///   - leader: 리더 정보
    ///   - members: 멤버 목록
    @MainActor
    func createGroup(
        name: String,
        part: UMCPartType,
        leader: ChallengerInfo,
        members: [ChallengerInfo]
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else {
            alertPrompt = AlertPrompt(
                title: "그룹 생성 실패",
                message: "그룹 이름을 입력해 주세요.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        let memberIds = members
            .map(\.challengerId)
            .filter { $0 != leader.challengerId }

        do {
            try await useCase.createStudyGroup(
                name: trimmedName,
                part: part,
                leaderId: leader.challengerId,
                memberIds: memberIds
            )

            if let updatedGroups = try? await useCase.fetchStudyGroups() {
                studyGroups = normalizeStudyGroups(updatedGroups)
            }

            if let updatedDetails = try? await useCase.fetchStudyGroupDetails(),
               !updatedDetails.isEmpty {
                studyGroupDetails = updatedDetails
                hasLoadedStudyGroupDetails = true
            } else {
                studyGroupDetails.append(
                    StudyGroupInfo(
                        serverID: "new_\(UUID().uuidString)",
                        name: trimmedName,
                        part: part,
                        createdDate: Date(),
                        leader: StudyGroupMember(
                            serverID: String(leader.memberId),
                            name: leader.name,
                            nickname: leader.nickname,
                            university: leader.schoolName,
                            profileImageURL: leader.profileImage,
                            role: .leader
                        ),
                        members: members.compactMap {
                            $0.memberId != leader.memberId ? StudyGroupMember(
                                serverID: String($0.memberId),
                                name: $0.name,
                                nickname: $0.nickname,
                                university: $0.schoolName,
                                profileImageURL: $0.profileImage
                            ) : nil
                        }
                    )
                )
            }

            hasLoadedStudyGroupDetails = true

            return true
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "그룹 생성 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "createStudyGroup"
            ))
            return false
        }
    }

    /// 그룹 삭제 확인 다이얼로그 표시
    func deleteGroup(_ group: StudyGroupInfo) {
        alertPrompt = AlertPrompt(
            title: "그룹 삭제",
            message: "'\(group.name)' 그룹을 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    guard let serverGroupId = Int(group.serverID) else {
                        self.alertPrompt = AlertPrompt(
                            title: "삭제 실패",
                            message: "유효하지 않은 그룹 ID입니다.",
                            positiveBtnTitle: "확인"
                        )
                        return
                    }

                    do {
                        try await self.useCase.deleteStudyGroup(
                            groupId: serverGroupId
                        )

                        self.removeGroupFromLocalState(group.serverID)
                    } catch let error as DomainError {
                        self.alertPrompt = AlertPrompt(
                            title: "삭제 실패",
                            message: error.userMessage,
                            positiveBtnTitle: "확인"
                        )
                    } catch {
                        self.errorHandler.handle(error, context: ErrorContext(
                            feature: "Activity",
                            action: "deleteStudyGroup"
                        ))
                    }
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 주차 필터 변경 시 멤버 목록 갱신
    func selectWeek(_ week: Int) {
        Task { @MainActor [weak self] in
            await self?.fetchMembers()
        }
    }

    /// 스터디 그룹 필터 변경 시 멤버 목록 갱신
    func selectStudyGroup(_ group: StudyGroupItem) {
        Task { @MainActor [weak self] in
            await self?.fetchMembers()
        }
    }

    /// 시트 dismiss 후 대기 중인 AlertPrompt를 표시
    func presentPendingAlert() {
        guard let pending = pendingAlertPrompt else { return }
        pendingAlertPrompt = nil
        alertPrompt = pending
    }

    /// 검토 시트 표시를 위해 제출 URL을 조회한 뒤 멤버를 선택 상태로 설정
    /// - Parameter member: 대상 멤버
    func openReviewSheet(for member: StudyMemberItem) {
        guard let challengerWorkbookId = member.challengerWorkbookId else {
            selectedMemberForReview = member
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let submissionURL = try await self.useCase.fetchWorkbookSubmissionURL(
                    challengerWorkbookId: challengerWorkbookId
                )
                let resolvedMember = StudyMemberItem(
                    id: member.id,
                    serverID: member.serverID,
                    challengerWorkbookId: member.challengerWorkbookId,
                    name: member.name,
                    nickname: member.nickname,
                    part: member.part,
                    university: member.university,
                    studyTopic: member.studyTopic,
                    week: member.week,
                    profileImageURL: member.profileImageURL,
                    submissionURL: submissionURL ?? member.submissionURL,
                    isBestWorkbook: member.isBestWorkbook
                )
                self.selectedMemberForReview = resolvedMember
            } catch {
                self.selectedMemberForReview = member
            }
        }
    }

    /// 스터디 승인(PASS) 제출
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - feedback: 피드백 내용
    func submitReviewApproval(
        member: StudyMemberItem,
        feedback: String
    ) async -> Bool {
        await submitReview(
            member: member,
            feedback: feedback,
            isApproved: true
        )
    }

    /// 스터디 반려 확인 다이얼로그 준비
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - feedback: 피드백 내용
    func submitReviewRejection(
        member: StudyMemberItem,
        feedback: String
    ) async -> Bool {
        await submitReview(
            member: member,
            feedback: feedback,
            isApproved: false
        )
    }

    /// 베스트 워크북 선정 제출
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - recommendation: 추천 사유
    func submitBestWorkbookSelection(
        member: StudyMemberItem,
        recommendation: String
    ) async -> Bool {
        await submitBestWorkbook(
            member: member,
            recommendation: recommendation
        )
    }

    private func submitReview(
        member: StudyMemberItem,
        feedback: String,
        isApproved: Bool
    ) async -> Bool {
        guard let challengerWorkbookId = member.challengerWorkbookId else {
            alertPrompt = AlertPrompt(
                title: "검토 실패",
                message: "워크북 식별자를 찾을 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        do {
            try await useCase.reviewWorkbook(
                challengerWorkbookId: challengerWorkbookId,
                isApproved: isApproved,
                feedback: feedback
            )
            removeMember(member)
            return true
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "검토 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "reviewWorkbook"
            ))
            return false
        }
    }

    private func submitBestWorkbook(
        member: StudyMemberItem,
        recommendation: String
    ) async -> Bool {
        guard let challengerWorkbookId = member.challengerWorkbookId else {
            alertPrompt = AlertPrompt(
                title: "선정 실패",
                message: "워크북 식별자를 찾을 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        do {
            try await useCase.selectBestWorkbook(
                challengerWorkbookId: challengerWorkbookId,
                bestReason: recommendation
            )
            markAsBestWorkbook(member)
            return true
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "선정 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "selectBestWorkbook"
            ))
            return false
        }
    }

    // MARK: - Private

    /// 서버 제출 완료된 멤버를 목록에서 제거
    private func removeMember(_ member: StudyMemberItem) {
        allMembers.removeAll { $0.id == member.id }
        filterMembers()
    }

    /// 멤버를 베스트 워크북으로 표시
    private func markAsBestWorkbook(_ member: StudyMemberItem) {
        guard let index = allMembers.firstIndex(
            where: { $0.id == member.id }
        ) else { return }
        allMembers[index].isBestWorkbook = true
        filterMembers()
    }

    /// 선택된 스터디 그룹과 주차에 따라 멤버 필터링
    private func filterMembers() {
        #if DEBUG
        if isDebugSeedMode {
            var filtered = allMembers
                .filter { $0.week == selectedWeek }

            if selectedStudyGroup != .all,
               let targetPart = selectedStudyGroup.part {
                filtered = filtered.filter { $0.part == targetPart }
            }

            membersState = .loaded(filtered)
            return
        }
        #endif

        membersState = .loaded(allMembers)
    }

    /// 툴바 메뉴에 항상 `전체 스터디 그룹`이 포함되도록 정규화
    private func normalizeStudyGroups(
        _ groups: [StudyGroupItem]
    ) -> [StudyGroupItem] {
        var normalized: [StudyGroupItem] = [.all]
        for group in groups where group != .all {
            if !normalized.contains(group) {
                normalized.append(group)
            }
        }
        return normalized
    }

    /// 삭제 성공 후 로컬 상태에서 그룹 삭제 반영
    private func removeGroupFromLocalState(_ serverID: String) {
        studyGroupDetails.removeAll { $0.serverID == serverID }
        studyGroups.removeAll {
            $0.serverID == serverID && $0 != .all
        }

        if selectedStudyGroup.serverID == serverID {
            selectedStudyGroup = .all
        }
    }

    #if DEBUG
    @MainActor
    func seedForDebugState(_ state: ActivityDebugState) {
        switch state {
        case .loading, .allLoading:
            membersState = .loading
            studyGroupDetailsState = .loading
        case .loaded:
            weeks = Array(1...10)
            selectedWeek = 1
            studyGroups = normalizeStudyGroups(StudyGroupItem.preview)
            studyGroupDetails = StudyGroupPreviewData.groups
            studyGroupDetailsState = .loaded(studyGroupDetails)

            hasLoadedSubmissionFilters = true
            hasLoadedStudyGroupDetails = true

            allMembers = ActivityDebugState.studyMembersAllWeeks
            isDebugSeedMode = true
            filterMembers()
        case .failed:
            membersState = .failed(.unknown(message: "스터디 관리 데이터를 불러오지 못했습니다."))
            studyGroupDetailsState = .failed(.unknown(message: "스터디 관리 데이터를 불러오지 못했습니다."))
        }
    }
    #endif
}
