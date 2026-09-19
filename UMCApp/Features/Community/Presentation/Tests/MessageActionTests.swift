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

    @Test("수정할 수 있으면 복사 다음에 수정을 낸다")
    func insertsEditAfterCopy() {
        let actions = MessageAction.items(
            deliveryState: .sent,
            canReport: false,
            canDelete: true,
            canEdit: true
        )

        #expect(actions == [.reply, .copy, .edit, .delete])
    }

    /// 삭제만 파괴적이다 — 신고까지 빨강이면 되돌릴 수 없는 쪽이 어디인지 흐려진다.
    @Test("파괴적 항목은 삭제뿐이다")
    func marksOnlyDeleteAsDestructive() {
        #expect(MessageAction.delete.isDestructive)
        #expect(!MessageAction.reply.isDestructive)
        #expect(!MessageAction.copy.isDestructive)
        #expect(!MessageAction.edit.isDestructive)
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

    /// 말풍선 아래에 자리가 있으면 시안 배치 그대로 — 반응 바는 위, 메뉴는 아래.
    @Test("자리가 있으면 메뉴를 말풍선 아래에 둔다")
    func placesMenuBelowBubble() {
        let origins = MessageActionLayout.verticalOrigins(
            bubbleFrame: CGRect(x: 16, y: 300, width: 200, height: 44),
            barHeight: 50,
            menuHeight: 180,
            containerHeight: 874,
            margin: 16,
            gap: 8
        )

        #expect(origins.bar == 242)
        #expect(origins.menu == 352)
    }

    /// 최근 메시지는 화면 아래에 있다. 메뉴를 따로 끌어올리면 반응 바를 덮고, 위에 그려진
    /// 메뉴가 이모지 탭을 가로채 답장이 눌렸다 (#1375).
    @Test("아래에 자리가 없으면 메뉴를 반응 바 위로 올려 겹치지 않게 한다")
    func movesMenuAboveBarNearBottom() {
        let origins = MessageActionLayout.verticalOrigins(
            bubbleFrame: CGRect(x: 16, y: 754, width: 200, height: 44),
            barHeight: 50,
            menuHeight: 180,
            containerHeight: 874,
            margin: 16,
            gap: 8
        )

        #expect(origins.bar == 696)
        #expect(origins.menu == 508)
        #expect(origins.menu + 180 <= origins.bar)
    }

    /// 위로 밀려 여백에 붙은 반응 바와, 그 바로 밑 말풍선 아래 메뉴가 서로 겹치면 안 된다.
    @Test("반응 바가 상단 여백에 붙어도 메뉴는 그 아래에서 시작한다")
    func keepsMenuBelowTopClampedBar() {
        let origins = MessageActionLayout.verticalOrigins(
            bubbleFrame: CGRect(x: 16, y: 0, width: 200, height: 44),
            barHeight: 50,
            menuHeight: 180,
            containerHeight: 874,
            margin: 16,
            gap: 8
        )

        #expect(origins.bar == 16)
        #expect(origins.menu == 74)
    }

    /// 화면을 거의 채운 긴 말풍선은 위아래 어디에도 메뉴 자리가 없다.
    @Test("위아래 모두 자리가 없으면 메뉴를 반응 바 바로 아래에 붙인다")
    func stacksMenuUnderBarForTallBubble() {
        let origins = MessageActionLayout.verticalOrigins(
            bubbleFrame: CGRect(x: 16, y: 100, width: 200, height: 740),
            barHeight: 50,
            menuHeight: 180,
            containerHeight: 874,
            margin: 16,
            gap: 8
        )

        #expect(origins.bar == 42)
        #expect(origins.menu == 100)
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

// MARK: - Emoji Picker

@Suite("EmojiPickerSheet")
struct EmojiPickerSheetTests {

    /// 서버는 그래파임 하나만 받는다. 목록에 하나라도 걸리는 게 섞이면 고른 반응이 매번 실패한다.
    @Test("전체 이모지 목록은 비어 있지 않고 전부 반응 검증을 통과한다")
    func listsOnlyValidReactionEmojis() throws {
        #expect(EmojiPickerSheet.emojis.count > 1_000)
        #expect(Set(EmojiPickerSheet.emojis).count == EmojiPickerSheet.emojis.count)

        for emoji in EmojiPickerSheet.emojis {
            try CommunityThreadRoomUseCase.validateReactionEmoji(emoji)
        }
    }
}
