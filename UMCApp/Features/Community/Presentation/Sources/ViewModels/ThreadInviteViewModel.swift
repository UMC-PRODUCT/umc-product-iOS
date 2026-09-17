//
//  ThreadInviteViewModel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation
import Observation
import CommunityDomain
import CoreDomain
import UMCFoundation

/// 기존 스레드에 참여자를 추가 초대하는 상태.
///
/// 선택 화면은 Activity 의 `SelectedChallengerView` 를 그대로 쓴다 — 일정 등록·스레드 생성과 같은
/// 화면이다 (#1421). 그 화면에는 전송 버튼이 없어 스터디 멤버 변경(`OperatorStudyManagementView`)
/// 처럼 **시트를 닫을 때** 보낸다. 선택은 시트가 아니라 여기 있어야 실패 뒤 다시 열어도 남는다.
///
/// 이미 참여 중인 멤버·정원 초과는 미리 거르지 않는다. 검색 화면은 챌린저 전체를 보여 주고, 서버가
/// 요청 전체를 사유와 함께 거절하므로(409) 그 사유를 알리고 선택을 남겨 고쳐 보내게 한다.
@Observable
@MainActor
public final class ThreadInviteViewModel {

    // MARK: - Property

    /// `SelectedChallengerView` 가 통째로 되쓰는 선택 목록. 초대에 성공해야 비운다.
    public var invitees: [ChallengerInfo] = []
    public var alertPrompt: AlertPrompt?

    /// 요청 중에 시트를 다시 열고 닫으면 같은 인원이 한 번 더 실린다 — 서버가 이미 참여 중이라고
    /// 거절해 성공한 초대가 실패로 보이게 된다.
    private var isInviting = false

    private let threadId: String
    private let useCase: CommunityThreadInviteUseCaseProtocol

    // MARK: - Init

    public init(threadId: String, useCase: CommunityThreadInviteUseCaseProtocol) {
        self.threadId = threadId
        self.useCase = useCase
    }

    // MARK: - Function

    /// 고른 인원을 초대한다. 실패하면 선택은 그대로 둔다 — 다시 고르게 하면 고른 시간을 통째로
    /// 버리게 된다.
    ///
    /// - Returns: 초대한 인원 수. 보낼 사람이 없거나 실패하면 `nil`.
    public func invite() async -> Int? {
        guard !invitees.isEmpty, !isInviting else { return nil }
        isInviting = true
        defer { isInviting = false }

        // 같은 사람이 두 번 실리면 서버가 한 사람을 두 번 넣으려 한다.
        let memberIds = Array(Set(invitees.map(\.memberId)))

        do {
            try await useCase.invite(threadId: threadId, memberIds: memberIds)
            invitees = []
            return memberIds.count
        } catch {
            alertPrompt = AlertPrompt(
                title: "초대하지 못했어요",
                message: AppError.from(error).userMessage,
                positiveBtnTitle: "확인"
            )
            return nil
        }
    }
}
