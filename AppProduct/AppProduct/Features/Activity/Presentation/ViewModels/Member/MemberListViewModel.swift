//
//  MemberListViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import SwiftUI

/// 멤버 목록 화면의 상태를 관리하는 ViewModel
@Observable
final class MemberListViewModel {
    // MARK: - Dependency
    
    private let fetchMembersUseCase: FetchMembersUseCaseProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - Properties
    
    var searchText: String = ""
    var selectedMember: MemberManagementItem?
    private(set) var membersState: Loadable<[MemberManagementItem]> = .idle
    var alertPrompt: AlertPrompt?
    private(set) var isSubmittingOutPoint: Bool = false
    private(set) var isDeletingOutPoint: Bool = false
    private(set) var isLoadingMemberDetail: Bool = false
    
    // MARK: - Init
    
    init(
        fetchMembersUseCase: FetchMembersUseCaseProtocol,
        errorHandler: ErrorHandler
    ) {
        self.fetchMembersUseCase = fetchMembersUseCase
        self.errorHandler = errorHandler
    }
    
    // MARK: - Computed Properties
    
    /// 검색어로 필터링된 멤버 목록
    private var filteredMembers: [MemberManagementItem] {
        guard case .loaded(let items) = membersState else {
            return []
        }
        
        if searchText.isEmpty {
            return items
        }
        
        return items.filter { member in
            member.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Part별로 그룹핑된 멤버 목록
    var groupedMembers: [(part: UMCPartType, members: [MemberManagementItem])] {
        let grouped = Dictionary(grouping: filteredMembers, by: { $0.part })
        return grouped
            .map { (part: $0.key, members: $0.value) }
            .sorted { $0.part.sortOrder < $1.part.sortOrder }
    }
    
    /// 검색 결과가 비어있는지 여부
    var isSearchResultEmpty: Bool {
        !searchText.isEmpty && filteredMembers.isEmpty
    }
    
    // MARK: - Action

    /// 멤버 전체 목록을 조회합니다.
    @MainActor
    func fetchMembers() async {
        membersState = .loading
        do {
            let members = try await fetchMembersUseCase.execute()
            membersState = .loaded(members)
        } catch let error as AppError {
            membersState = .failed(error)
        } catch let error as DomainError {
            membersState = .failed(.domain(error))
        } catch let error as NetworkError {
            membersState = .failed(.network(error))
        } catch let error as RepositoryError {
            membersState = .failed(.repository(error))
        } catch {
            membersState = .failed(
                .unknown(message: error.localizedDescription)
            )
        }
    }

    /// 멤버에게 아웃 포인트를 부여합니다.
    ///
    /// - Parameters:
    ///   - member: 아웃을 부여할 멤버
    ///   - reason: 아웃 사유
    /// - Returns: 성공 여부
    @MainActor
    func submitOutPoint(
        member: MemberManagementItem,
        reason: String
    ) async -> Bool {
        let trimmedReason = reason.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedReason.isEmpty else {
            alertPrompt = AlertPrompt(
                title: "아웃 부여 실패",
                message: "아웃 사유를 입력해 주세요.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        guard let challengerId = member.challengerID else {
            alertPrompt = AlertPrompt(
                title: "아웃 부여 실패",
                message: "챌린저 ID를 찾을 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        isSubmittingOutPoint = true
        defer { isSubmittingOutPoint = false }

        do {
            try await fetchMembersUseCase.grantOutPoint(
                challengerId: challengerId,
                description: trimmedReason
            )

            try await reloadMembersAndReselect(member: member)
            return true
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "아웃 부여 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Activity",
                    action: "submitOutPoint"
                )
            )
            return false
        }
    }

    /// 챌린저 멤버 상세 시트를 표시합니다.
    ///
    /// 출석 기록을 조회한 뒤 `selectedMember`를 설정합니다.
    /// 조회 실패 시 기존 멤버 데이터 그대로 시트를 표시합니다.
    ///
    /// - Parameter member: 상세 정보를 표시할 멤버
    @MainActor
    func openChallengerMemberDetail(
        _ member: MemberManagementItem
    ) async {
        guard let challengerId = member.challengerID else {
            selectedMember = member
            return
        }

        isLoadingMemberDetail = true
        defer { isLoadingMemberDetail = false }

        do {
            let records = try await fetchMembersUseCase.fetchAttendanceRecords(
                challengerId: challengerId
            )
            selectedMember = MemberManagementItem(
                id: member.id,
                memberID: member.memberID,
                challengerID: member.challengerID,
                profile: member.profile,
                name: member.name,
                nickname: member.nickname,
                generation: member.generation,
                school: member.school,
                position: member.position,
                part: member.part,
                penalty: member.penalty,
                badge: member.badge,
                managementTeam: member.managementTeam,
                attendanceRecords: records,
                penaltyHistory: member.penaltyHistory
            )
        } catch {
            selectedMember = member
        }
    }

    /// 아웃 포인트 기록을 삭제합니다.
    ///
    /// - Parameters:
    ///   - member: 아웃을 삭제할 멤버
    ///   - history: 삭제할 아웃 이력 항목
    /// - Returns: 성공 여부
    @MainActor
    func deleteOutPoint(
        member: MemberManagementItem,
        history: OperatorMemberPenaltyHistory
    ) async -> Bool {
        guard let challengerPointId = history.challengerPointId else {
            alertPrompt = AlertPrompt(
                title: "아웃 삭제 실패",
                message: "삭제할 아웃 포인트 ID를 찾을 수 없습니다.",
                positiveBtnTitle: "확인"
            )
            return false
        }

        isDeletingOutPoint = true
        defer { isDeletingOutPoint = false }

        do {
            try await fetchMembersUseCase.deleteOutPoint(
                challengerPointId: challengerPointId
            )
            try await reloadMembersAndReselect(member: member)
            return true
        } catch let error as DomainError {
            alertPrompt = AlertPrompt(
                title: "아웃 삭제 실패",
                message: error.userMessage,
                positiveBtnTitle: "확인"
            )
            return false
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Activity",
                    action: "deleteOutPoint"
                )
            )
            return false
        }
    }

    @MainActor
    private func reloadMembersAndReselect(
        member: MemberManagementItem
    ) async throws {
        let updatedMembers = try await fetchMembersUseCase.execute()
        membersState = .loaded(updatedMembers)
        guard let resolvedMember = resolveMember(
            in: updatedMembers,
            from: member
        ) else {
            selectedMember = nil
            return
        }

        selectedMember = memberWithStableSheetIdentity(
            base: member,
            updated: resolvedMember
        )
    }

    private func resolveMember(
        in members: [MemberManagementItem],
        from target: MemberManagementItem
    ) -> MemberManagementItem? {
        members.first(where: {
            if let targetMemberId = target.memberID,
               let memberId = $0.memberID,
               targetMemberId == memberId {
                return true
            }

            if let targetChallengerId = target.challengerID,
               let challengerId = $0.challengerID,
               targetChallengerId == challengerId {
                return true
            }

            return false
        })
    }

    /// `sheet(item:)`는 `id`가 바뀌면 다른 시트로 인식해 닫았다가 다시 엽니다.
    /// 서버 재조회 후 데이터는 최신 값으로 바꾸되, 시트 식별자는 유지합니다.
    private func memberWithStableSheetIdentity(
        base: MemberManagementItem,
        updated: MemberManagementItem
    ) -> MemberManagementItem {
        MemberManagementItem(
            id: base.id,
            memberID: updated.memberID,
            challengerID: updated.challengerID,
            profile: updated.profile,
            name: updated.name,
            nickname: updated.nickname,
            generation: updated.generation,
            school: updated.school,
            position: updated.position,
            part: updated.part,
            penalty: updated.penalty,
            badge: updated.badge,
            managementTeam: updated.managementTeam,
            attendanceRecords: updated.attendanceRecords,
            penaltyHistory: updated.penaltyHistory
        )
    }

}
