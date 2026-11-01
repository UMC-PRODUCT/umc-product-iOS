//
//  ThreadMemberListViewModel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation
import Observation
import CommunityDomain
import UMCFoundation

/// 참여자 목록 상태 기계.
///
/// 내 권한은 세션이 아니라 **목록에 실려 온 내 행의 역할**에서 읽는다. 스레드 상세의
/// `myRole` 로도 알 수 있지만 위임 직후 두 값이 어긋나는 구간이 생긴다 — 방금 위임한 화면에서
/// 옛 권한으로 메뉴가 계속 열리는 게 그 증상이다.
@Observable
@MainActor
public final class ThreadMemberListViewModel {

    // MARK: - Property

    public private(set) var state: Loadable<[ThreadMember]> = .idle
    public var alertPrompt: AlertPrompt?
    public var searchText = ""
    public private(set) var isSelecting = false
    public private(set) var selectedMemberIds = Set<String>()
    public private(set) var isManaging = false
    public private(set) var operationMessage: String?

    public enum ManagementAction: Sendable {
        case promote, demote, kick

        var title: String {
            switch self {
            case .promote: return "관리자 지정"
            case .demote: return "관리자 해제"
            case .kick: return "내보내기"
            }
        }
    }
    /// 나가기·삭제가 확정된 상태. View 가 이걸 보고 커뮤니티 루트로 되돌린다 — 둘 다 결과가
    /// "이 스레드가 내 목록에서 사라졌다" 로 같아 플래그를 나누지 않는다.
    public private(set) var didLeave = false

    private let threadId: String
    private let useCase: CommunityThreadMemberUseCaseProtocol
    private let errorHandler: ErrorHandler
    public let currentMemberId: String?

    // MARK: - Init

    /// - Parameter currentMemberId: 내 행을 가려 내는 유일한 열쇠. 없으면 관리 메뉴를 열지 않는다.
    public init(
        threadId: String,
        useCase: CommunityThreadMemberUseCaseProtocol,
        errorHandler: ErrorHandler,
        currentMemberId: String? = AppStorageKey.memberIdString()
    ) {
        self.threadId = threadId
        self.useCase = useCase
        self.errorHandler = errorHandler
        self.currentMemberId = currentMemberId
    }

    // MARK: - Computed Property

    public var members: [ThreadMember] {
        var seen = Set<String>()
        return (state.value ?? []).filter { seen.insert($0.id).inserted }.sorted {
            let lhsRank = sortRank($0)
            let rhsRank = sortRank($1)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            let order = $0.name.compare($1.name, locale: Locale(identifier: "ko_KR"))
            return order == .orderedSame ? $0.id < $1.id : order == .orderedAscending
        }
    }

    private func sortRank(_ member: ThreadMember) -> Int {
        if isMe(member) { return 0 }
        switch member.role {
        case .owner: return 1
        case .admin: return 2
        case .member: return 3
        }
    }

    public var filteredMembers: [ThreadMember] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? members : members.filter { $0.name.localizedStandardContains(query) }
    }

    private var selectedMembers: [ThreadMember] {
        members.filter { selectedMemberIds.contains($0.id) && canKick($0) }
    }

    public var canManageSelection: Bool {
        !isManaging && !selectedMembers.isEmpty
    }

    public var canPromoteSelection: Bool {
        canManageSelection && isOwner && selectedMembers.allSatisfy { $0.role == .member }
    }

    public var canDemoteSelection: Bool {
        canManageSelection && isOwner && selectedMembers.allSatisfy { $0.role == .admin }
    }

    /// 내가 개설자인지. 서버 역할이 유일한 근거라 목록을 받기 전에는 `false` 다.
    public var isOwner: Bool {
        myRole == .owner
    }

    /// 초대 진입점을 열지. 개설자·관리자 둘 다 연다 (서버 `requireManager`).
    public var canInvite: Bool {
        myRole?.canManageMembers == true
    }

    private var myRole: ThreadMemberRole? {
        members.first { isMe($0.id) }?.role
    }

    /// 나가기를 막는 이유. `nil` 이면 나갈 수 있다.
    ///
    /// #1131 결정 2 — 개설자는 위임 전까지 나갈 수 없다. 위임할 상대조차 없으면 나가기가 아니라
    /// 스레드 삭제가 정답이라 안내 문구를 나눈다.
    public var leaveBlockReason: String? {
        guard isOwner else { return nil }
        return members.contains { !isMe($0.id) }
            ? Constants.delegateFirstReason
            : Constants.deleteInsteadReason
    }

    /// 나가기 버튼 활성 조건. 목록을 받기 전에는 내 역할을 모르므로 잠가 둔다.
    public var canLeave: Bool {
        state.value != nil && leaveBlockReason == nil
    }

    /// 삭제가 유일한 출구인지 (#1131 결정 2 → #1134).
    ///
    /// 개설자이면서 참여자가 나뿐일 때만 연다. 안내 문구만 띄우고 버튼을 주지 않으면
    /// "삭제해 주세요" 를 읽은 사용자가 삭제할 곳을 찾아 다녀야 한다.
    public var canDeleteThread: Bool {
        isOwner && !members.contains { !isMe($0.id) }
    }

    // MARK: - Function

    public func load() async {
        guard !isManaging else { return }
        state = .loading
        do {
            state = .loaded(try await useCase.loadMembers(threadId: threadId))
            selectedMemberIds.formIntersection(members.filter { canKick($0) }.map(\.id))
            if !canInvite { isSelecting = false }
        } catch {
            // 취소는 화면을 떠난 정상 흐름이다. 에러 화면으로 바꾸면 안 된다.
            guard !(error is CancellationError) else { return }
            state = .failed(AppError.from(error))
        }
    }

    public func toggleSelectionMode() {
        guard canInvite, !isManaging else { return }
        isSelecting.toggle()
        selectedMemberIds.removeAll()
        operationMessage = nil
    }

    public func toggleSelection(_ member: ThreadMember) {
        guard isSelecting, !isManaging,
              let current = members.first(where: { $0.id == member.id }), canKick(current) else { return }
        if !selectedMemberIds.insert(current.id).inserted {
            selectedMemberIds.remove(current.id)
        }
    }

    public func confirmSelection(_ action: ManagementAction) {
        guard isActionAllowed(action) else { return }
        let ids = selectedMemberIds
        alertPrompt = AlertPrompt(
            title: "선택한 \(selectedMembers.count)명을 \(action.title)할까요?",
            message: action == .kick
                ? "내보낸 참여자는 다시 초대해야 참여할 수 있어요."
                : "선택한 참여자의 스레드 관리 권한이 변경돼요.",
            positiveBtnTitle: action.title,
            positiveBtnAction: { [weak self] in
                Task { @MainActor in
                    guard let self, self.selectedMemberIds == ids else { return }
                    await self.manageSelection(action)
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: action != .promote
        )
    }

    /// 단건 API의 실제 성공 결과만 반영한다. 일부 실패 시 실패한 대상의 선택을 남긴다.
    func manageSelection(_ action: ManagementAction) async {
        guard isActionAllowed(action) else { return }
        let targets = selectedMembers
        isManaging = true
        operationMessage = nil
        defer { isManaging = false }
        var succeeded = Set<String>()
        for target in targets {
            guard !Task.isCancelled else { break }
            do {
                switch action {
                case .kick:
                    try await useCase.kick(threadId: threadId, memberId: target.id)
                    state = .loaded(members.filter { $0.id != target.id })
                case .promote, .demote:
                    try await useCase.setAdministrator(
                        threadId: threadId,
                        memberId: target.id,
                        isAdministrator: action == .promote
                    )
                    state = .loaded(members.map { member in
                        guard member.id == target.id else { return member }
                        return ThreadMember(
                            id: member.id, name: member.name, part: member.part,
                            profileImageURL: member.profileImageURL,
                            role: action == .promote ? .admin : .member
                        )
                    })
                }
                succeeded.insert(target.id)
            } catch {
                if error is CancellationError { break }
                guard isTargetFailure(error) else {
                    errorHandler.handle(error, context: errorContext("manageThreadMembers"))
                    break
                }
            }
        }
        selectedMemberIds.subtract(succeeded)
        let failedCount = targets.count - succeeded.count
        operationMessage = failedCount == 0
            ? "\(succeeded.count)명 \(action.title)이 완료되었어요."
            : "\(succeeded.count)명 완료, \(failedCount)명 처리에 실패했어요. 다시 시도해 주세요."
        if selectedMemberIds.isEmpty { isSelecting = false }
    }

    /// 서버가 명시한 대상별 오류만 건너뛴다. 인증·권한·전송 오류는 전체 작업을 중단한다.
    private func isTargetFailure(_ error: Error) -> Bool {
        let code: String?
        switch AppError.from(error) {
        case .repository(.serverError(let serverCode, _)):
            code = serverCode
        case .network(.requestFailed(_, let data)):
            let payload = data.flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
            }
            code = payload?["code"] as? String
        default:
            code = nil
        }
        // 멤버 없음 / 개설자는 강퇴 불가 / 유효하지 않은 역할 변경.
        return code.map { ["COMMUNITY-0035", "COMMUNITY-0042", "COMMUNITY-0043"].contains($0) }
            ?? false
    }

    private func isActionAllowed(_ action: ManagementAction) -> Bool {
        guard isSelecting else { return false }
        switch action {
        case .promote: return canPromoteSelection
        case .demote: return canDemoteSelection
        case .kick: return canManageSelection
        }
    }

    /// 내 행인지. "(나)" 표시와 관리 메뉴 판정이 같은 기준을 봐야 한다.
    public func isMe(_ member: ThreadMember) -> Bool {
        isMe(member.id)
    }

    /// 행의 `내보내기` 를 열지. 개설자·관리자만, 내 행과 개설자 행에는 열지 않는다 —
    /// 자기를 내보내거나 개설자를 내보내는 조합은 서버도 거절한다.
    public func canKick(_ member: ThreadMember) -> Bool {
        canInvite && !isMe(member.id) && member.role != .owner
    }

    /// 행의 `개설자 위임` 을 열지. 개설자만, 내 행에는 열지 않는다 (서버 `changeRole`).
    public func canTransferOwnership(to member: ThreadMember) -> Bool {
        isOwner && !isMe(member.id)
    }

    /// 내보내기 확인. 되돌릴 수 없어 재초대 조건까지 알린다 (시안 #37).
    public func confirmKick(_ member: ThreadMember) {
        guard !isManaging, canKick(member) else { return }

        alertPrompt = AlertPrompt(
            title: "\(member.name) 님을 내보낼까요?",
            message: "내보낸 참여자는 다시 초대해야 참여할 수 있어요.",
            positiveBtnTitle: "내보내기",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.kick(member) }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 개설자 위임 확인. 내 권한을 넘기는 비가역 작업이라 한 번 묻는다.
    public func confirmTransferOwnership(to member: ThreadMember) {
        guard !isManaging, canTransferOwnership(to: member) else { return }

        alertPrompt = AlertPrompt(
            title: "\(member.name) 님에게 개설자를 위임할까요?",
            message: "위임하면 되돌릴 수 없고, 나는 관리자가 돼요.",
            positiveBtnTitle: "위임",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.transferOwnership(to: member) }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 나가기 확인. 재참여 조건을 함께 알린다 (시안 #30).
    public func confirmLeave() {
        guard !isManaging, canLeave else { return }

        alertPrompt = AlertPrompt(
            title: "스레드를 나갈까요?",
            message: "나가면 대화 내용을 볼 수 없고, 다시 참여하려면 초대를 받아야 해요.",
            positiveBtnTitle: "나가기",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.leave() }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 스레드 삭제 확인. 나가기와 달리 남는 사람이 없어 대화까지 함께 사라진다.
    public func confirmDeleteThread() {
        guard !isManaging, canDeleteThread else { return }

        alertPrompt = AlertPrompt(
            title: "스레드를 삭제할까요?",
            message: "대화 내용이 모두 사라져요. 되돌릴 수 없어요.",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.deleteThread() }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    // MARK: - Private Function

    private func isMe(_ memberId: String) -> Bool {
        guard let currentMemberId, !currentMemberId.isEmpty else { return false }
        return memberId == currentMemberId
    }

    /// 먼저 지워 놓고 보낸다. 실패하면 스냅샷으로 되돌린다 — 목록에서 사라진 사람이 다시
    /// 나타나는 편이, 서버에 남아 있는 사람이 없는 것처럼 보이는 것보다 낫다.
    private func kick(_ member: ThreadMember) async {
        guard !isManaging, let current = members.first(where: { $0.id == member.id }),
              canKick(current) else { return }
        isManaging = true
        defer { isManaging = false }
        let snapshot = state
        state = .loaded(members.filter { $0.id != member.id })

        do {
            try await useCase.kick(threadId: threadId, memberId: member.id)
        } catch {
            state = snapshot
            errorHandler.handle(error, context: errorContext("kickThreadMember"))
        }
    }

    /// 위임은 내 역할까지 함께 바꾼다. 성공 뒤 서버 값을 다시 읽는 이유는, 이전 개설자를
    /// `ADMIN` 으로 둘지 `MEMBER` 로 둘지가 서버 정책이라 클라이언트가 추측하면 배지가 어긋나서다.
    private func transferOwnership(to member: ThreadMember) async {
        guard !isManaging,
              let target = members.first(where: { $0.id == member.id }),
              canTransferOwnership(to: target) else { return }
        isManaging = true
        defer { isManaging = false }
        do {
            try await useCase.transferOwnership(threadId: threadId, to: target.id)
            state = .loaded(try await useCase.loadMembers(threadId: threadId))
            selectedMemberIds.removeAll()
            isSelecting = false
        } catch {
            errorHandler.handle(error, context: errorContext("transferThreadOwnership"))
        }
    }

    /// 개설자 차단은 버튼에서 이미 걸리지만, 서버 409 를 받기 전 마지막 방어선으로 한 번 더 본다.
    private func leave() async {
        guard !isManaging, canLeave else { return }
        isManaging = true
        defer { isManaging = false }

        do {
            try await useCase.leave(threadId: threadId)
            didLeave = true
        } catch {
            errorHandler.handle(error, context: errorContext("leaveThread"))
        }
    }

    /// 나가기와 마찬가지로 마지막 방어선을 한 번 더 둔다 — 알럿이 떠 있는 동안 다른 기기에서
    /// 위임이 들어오면 조건이 무너진다.
    private func deleteThread() async {
        guard !isManaging, canDeleteThread else { return }
        isManaging = true
        defer { isManaging = false }

        do {
            try await useCase.deleteThread(threadId: threadId)
            didLeave = true
        } catch {
            errorHandler.handle(error, context: errorContext("deleteThread"))
        }
    }

    private func errorContext(_ action: String) -> ErrorContext {
        ErrorContext(
            feature: "Community",
            action: action,
            retryAction: { [weak self] in await self?.load() }
        )
    }
}

// MARK: - Constants

fileprivate enum Constants {
    static let delegateFirstReason = "먼저 다른 참여자에게 개설자를 위임해 주세요."
    static let deleteInsteadReason = "참여자가 나뿐이라 위임할 상대가 없어요. 스레드를 삭제해 주세요."
}
