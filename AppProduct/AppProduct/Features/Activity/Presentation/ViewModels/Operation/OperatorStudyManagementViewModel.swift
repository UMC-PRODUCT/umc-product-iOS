//
//  OperatorStudyManagementViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

@Observable
final class OperatorStudyManagementViewModel {
    // MARK: - Property

    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var useCase: FetchStudyMembersUseCaseProtocol

    private(set) var membersState: Loadable<[StudyMemberItem]> = .idle
    private(set) var studyGroups: [StudyGroupItem] = []
    var selectedStudyGroup: StudyGroupItem = .all
    private(set) var weeks: [Int] = []
    var selectedWeek: Int = 1

    /// 스터디 그룹 관리 상태
    var studyGroupDetail: StudyGroupInfo = .preview
    var showAddMemberSheet = false
    var selectedChallengers: [ChallengerInfo] = []

    /// 시트 표시 상태
    var selectedMemberForReview: StudyMemberItem?
    var selectedMemberForBest: StudyMemberItem?

    /// 확인 다이얼로그
    var alertPrompt: AlertPrompt?

    /// 시트 dismiss 후 표시할 대기 중인 AlertPrompt
    private var pendingAlertPrompt: AlertPrompt?

    /// 필터링 전 전체 멤버 목록
    private var allMembers: [StudyMemberItem] = []

    // MARK: - Initializer

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        useCase: FetchStudyMembersUseCaseProtocol
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.useCase = useCase
    }

    // MARK: - Function

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
        let existingIDs = Set(
            studyGroupDetail.members.map(\.serverID)
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
        studyGroupDetail.members.append(contentsOf: newMembers)
        selectedChallengers = []
    }

    func selectWeek(_ week: Int) {
        filterMembers()
    }

    func selectStudyGroup(_ group: StudyGroupItem) {
        filterMembers()
    }

    /// 시트 dismiss 후 대기 중인 AlertPrompt를 표시
    func presentPendingAlert() {
        guard let pending = pendingAlertPrompt else { return }
        pendingAlertPrompt = nil
        alertPrompt = pending
    }

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
