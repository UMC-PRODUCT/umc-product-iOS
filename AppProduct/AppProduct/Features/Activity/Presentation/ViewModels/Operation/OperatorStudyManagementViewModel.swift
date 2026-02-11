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

    /// 스터디 그룹 필터 목록
    private(set) var studyGroups: [StudyGroupItem] = []

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

    /// 스터디 멤버, 그룹, 주차 데이터를 서버에서 조회
    @MainActor
    func fetchMembers() async {
        membersState = .loading

        do {
            let members = try await useCase.fetchMembers()
            let groups = try await useCase.fetchStudyGroups()
            let fetchedWeeks = try await useCase.fetchWeeks()
            allMembers = members
            studyGroups = groups
            weeks = fetchedWeeks
            filterMembers()
        } catch let error as DomainError {
            membersState = .failed(.domain(error))
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchStudyMembers",
                retryAction: { [weak self] in
                    await self?.fetchMembers()
                }
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
                    serverID: String(challenger.challengeId),
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
    func applyGroupEdit(
        groupID: UUID,
        name: String,
        part: UMCPartType
    ) {
        guard let index = studyGroupDetails.firstIndex(
            where: { $0.id == groupID }
        ) else { return }

        let old = studyGroupDetails[index]
        studyGroupDetails[index] = StudyGroupInfo(
            id: old.id,
            serverID: old.serverID,
            name: name,
            part: part,
            createdDate: old.createdDate,
            leader: old.leader,
            members: old.members
        )
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
    func createGroup(
        name: String,
        part: UMCPartType,
        leader: ChallengerInfo,
        members: [ChallengerInfo]
    ) {
        let leaderMember = StudyGroupMember(
            serverID: String(leader.challengeId),
            name: leader.name,
            nickname: leader.nickname,
            university: leader.schoolName,
            profileImageURL: leader.profileImage,
            role: .leader
        )
        let memberList = members.map { challenger in
            StudyGroupMember(
                serverID: String(challenger.challengeId),
                name: challenger.name,
                nickname: challenger.nickname,
                university: challenger.schoolName,
                profileImageURL: challenger.profileImage
            )
        }
        let newGroup = StudyGroupInfo(
            serverID: "new_\(UUID().uuidString.prefix(8))",
            name: name,
            part: part,
            createdDate: Date(),
            leader: leaderMember,
            members: memberList
        )
        studyGroupDetails.append(newGroup)
    }

    /// 그룹 삭제 확인 다이얼로그 표시
    func deleteGroup(_ group: StudyGroupInfo) {
        alertPrompt = AlertPrompt(
            title: "그룹 삭제",
            message: "'\(group.name)' 그룹을 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                self?.studyGroupDetails.removeAll {
                    $0.id == group.id
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 주차 필터 변경 시 멤버 목록 갱신
    func selectWeek(_ week: Int) {
        filterMembers()
    }

    /// 스터디 그룹 필터 변경 시 멤버 목록 갱신
    func selectStudyGroup(_ group: StudyGroupItem) {
        filterMembers()
    }

    /// 시트 dismiss 후 대기 중인 AlertPrompt를 표시
    func presentPendingAlert() {
        guard let pending = pendingAlertPrompt else { return }
        pendingAlertPrompt = nil
        alertPrompt = pending
    }

    /// 스터디 승인 확인 다이얼로그 준비
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - feedback: 피드백 내용
    func confirmReviewApproval(member: StudyMemberItem, feedback: String) {
        pendingAlertPrompt = AlertPrompt(
            title: "스터디 승인",
            message: "\(member.displayName)님의 \(member.week)주차 스터디를 승인하시겠습니까?",
            positiveBtnTitle: "승인",
            positiveBtnAction: { [weak self] in
                self?.submitReview(member: member, feedback: feedback, isApproved: true)
            },
            negativeBtnTitle: "취소"
        )
    }

    /// 스터디 반려 확인 다이얼로그 준비
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - feedback: 피드백 내용
    func confirmReviewRejection(member: StudyMemberItem, feedback: String) {
        pendingAlertPrompt = AlertPrompt(
            title: "스터디 반려",
            message: "\(member.displayName)님의 \(member.week)주차 스터디를 반려하시겠습니까?",
            positiveBtnTitle: "반려",
            positiveBtnAction: { [weak self] in
                self?.submitReview(member: member, feedback: feedback, isApproved: false)
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 베스트 워크북 선정 확인 다이얼로그 준비
    /// - Parameters:
    ///   - member: 대상 멤버
    ///   - recommendation: 추천 사유
    func confirmBestWorkbookSelection(
        member: StudyMemberItem,
        recommendation: String
    ) {
        pendingAlertPrompt = AlertPrompt(
            title: "베스트 워크북 선정",
            message: "\(member.displayName)님을 베스트 워크북으로 선정하시겠습니까?",
            positiveBtnTitle: "선정",
            positiveBtnAction: { [weak self] in
                self?.submitBestWorkbook(
                    member: member,
                    recommendation: recommendation
                )
            },
            negativeBtnTitle: "취소"
        )
    }

    private func submitReview(
        member: StudyMemberItem,
        feedback: String,
        isApproved: Bool
    ) {
        // TODO: UseCase 연동
        removeMember(member)
    }

    private func submitBestWorkbook(
        member: StudyMemberItem,
        recommendation: String
    ) {
        // TODO: UseCase 연동
        markAsBestWorkbook(member)
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
        var filtered = allMembers

        // 1. 주차 필터
        filtered = filtered.filter { $0.week == selectedWeek }

        // 2. 스터디 그룹 필터
        if let targetPart = selectedStudyGroup.part {
            filtered = filtered.filter {
                $0.part == targetPart
            }
        }

        membersState = .loaded(filtered)
    }
}
