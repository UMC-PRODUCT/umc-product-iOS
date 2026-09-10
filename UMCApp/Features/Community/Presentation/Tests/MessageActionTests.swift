//
//  MessageActionTests.swift
//  CommunityPresentationTests
//

import Foundation
import Testing
import CommunityDomain
@testable import CommunityPresentation

// MARK: - Items

/// 액션 노출 규칙.
///
/// 미확정 메시지에 답장이 뜨거나 권한 없는 사람에게 삭제가 보이는 건 화면을 띄워도 조건을
/// 맞춰 놓기 전에는 재현되지 않는다 — 순수 함수로 떼어 네 조합을 그대로 잠근다.
@Suite("MessageAction.items")
struct MessageActionItemsTests {

    @Test("권한이 모두 있으면 답장·복사·신고·삭제 순으로 낸다")
    func listsAllActionsInOrder() {
        let actions = MessageAction.items(
            deliveryState: .sent,
            canReport: true,
            canDelete: true
        )

        #expect(actions == [.reply, .copy, .report, .delete])
    }

    @Test("아직 전송 중이면 답장을 빼고 낸다")
    func excludesReplyWhileSending() {
        let actions = MessageAction.items(
            deliveryState: .sending,
            canReport: true,
            canDelete: true
        )

        #expect(actions == [.copy, .report, .delete])
    }

    @Test("신고할 수 없으면 신고를 빼고 낸다")
    func excludesReportWhenNotAllowed() {
        let actions = MessageAction.items(
            deliveryState: .sent,
            canReport: false,
            canDelete: true
        )

        #expect(actions == [.reply, .copy, .delete])
    }

    @Test("삭제할 수 없으면 삭제를 빼고 낸다")
    func excludesDeleteWhenNotAllowed() {
        let actions = MessageAction.items(
            deliveryState: .sent,
            canReport: true,
            canDelete: false
        )

        #expect(actions == [.reply, .copy, .report])
    }

    /// 삭제만 파괴적이다 — 신고까지 빨강이면 되돌릴 수 없는 쪽이 어디인지 흐려진다.
    @Test("파괴적 항목은 삭제뿐이다")
    func marksOnlyDeleteAsDestructive() {
        #expect(MessageAction.delete.isDestructive)
        #expect(!MessageAction.reply.isDestructive)
        #expect(!MessageAction.copy.isDestructive)
        #expect(!MessageAction.report.isDestructive)
    }
}

// MARK: - Layout

/// 떠 있는 레이어의 원점 보정.
@Suite("MessageActionLayout")
struct MessageActionLayoutTests {

    @Test("화면 안에 들어오는 위치는 그대로 둔다")
    func keepsYInsideContainer() {
        let y = MessageActionLayout.clampedY(
            preferredY: 300,
            height: 50,
            containerHeight: 852,
            margin: 16
        )

        #expect(y == 300)
    }

    /// 첫 메시지를 롱프레스하면 반응 바가 화면 위로 넘어간다.
    @Test("상단 밖으로 나가면 여백만큼 내려 붙인다")
    func clampsYToTopMargin() {
        let y = MessageActionLayout.clampedY(
            preferredY: -30,
            height: 50,
            containerHeight: 852,
            margin: 16
        )

        #expect(y == 16)
    }

    /// 마지막 메시지를 롱프레스하면 메뉴가 화면 아래로 넘어간다.
    @Test("하단 밖으로 나가면 위로 끌어올린다")
    func clampsYToBottomMargin() {
        let y = MessageActionLayout.clampedY(
            preferredY: 800,
            height: 180,
            containerHeight: 852,
            margin: 16
        )

        #expect(y == 656)
    }

    @Test("컨테이너가 레이어보다 작으면 여백 자리에 붙인다")
    func fallsBackToMarginWhenContainerIsTooShort() {
        let y = MessageActionLayout.clampedY(
            preferredY: 300,
            height: 400,
            containerHeight: 380,
            margin: 16
        )

        #expect(y == 16)
    }

    @Test("상대 메시지는 좌측 여백에 붙인다")
    func alignsIncomingLayerToLeading() {
        let x = MessageActionLayout.clampedX(
            isMine: false,
            width: 312,
            containerWidth: 393,
            margin: 16
        )

        #expect(x == 16)
    }

    @Test("내 메시지는 우측 여백에 붙인다")
    func alignsOutgoingLayerToTrailing() {
        let x = MessageActionLayout.clampedX(
            isMine: true,
            width: 238,
            containerWidth: 393,
            margin: 16
        )

        #expect(x == 139)
    }

    /// 320pt 화면에서는 312pt 반응 바가 좌우 여백을 한 번에 넘긴다.
    @Test("좁은 화면에서는 좌측 여백까지만 물러난다")
    func clampsXToLeadingMarginOnNarrowScreen() {
        let x = MessageActionLayout.clampedX(
            isMine: true,
            width: 312,
            containerWidth: 320,
            margin: 16
        )

        #expect(x == 16)
    }
}
