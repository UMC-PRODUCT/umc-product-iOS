//
//  MessageActionOverlay.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/10/26.
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem

// MARK: - Constants

fileprivate enum Constants {
    /// 화면 가장자리 최소 여백. 좌우 정렬과 상하 보정이 같은 값을 쓴다.
    static let margin: CGFloat = 16
    /// 말풍선 ↔ 반응 바, 말풍선 ↔ 메뉴 사이 간격 (시안 실측).
    static let gap: CGFloat = 8
    static let reactionBarWidth: CGFloat = 312
    static let reactionBarHeight: CGFloat = 50
    /// 글리프 pitch 이자 탭 타깃. 6칸 × 50 + 좌우 6 = 312 로 시안 폭과 정확히 맞아떨어진다.
    static let reactionCell: CGFloat = 50
    static let reactionBarPadding: CGFloat = 6
    static let emojiSize: CGFloat = 26
    static let moreEmojiSize: CGFloat = 29
    static let menuWidth: CGFloat = 238
    static let menuItemHeight: CGFloat = 40
    static let menuVerticalPadding: CGFloat = 10
    /// 떠 있는 오버레이라 상속할 컨테이너가 없다 — ConcentricRectangle 대신 고정 반경을 쓴다.
    static let menuCornerRadius: CGFloat = 22
    static let menuIconSize: CGFloat = 18
    /// 아이콘 글리프 폭이 제각각이라 레이블 시작점이 흔들린다. 한 칸으로 묶어 세로줄을 맞춘다.
    static let menuIconWidth: CGFloat = 24
    /// 접근성 크기에서 항목 높이가 대략 두 배가 된다. 배치 기준값을 그대로 두면 카드가 화면
    /// 밖으로 밀려도 보정이 걸리지 않는다.
    static let accessibilityItemScale: CGFloat = 2
    /// 딤에 뚫는 구멍. 말풍선 모서리(16)와 같은 값이라 테두리가 어긋나 보이지 않는다.
    static let bubbleHoleRadius: CGFloat = 16
    static let dimOpacity: Double = 0.2
    static let deleteHint = "되돌릴 수 없어요"
    static let moreEmojiLabel = "이모지 더 보기"
    static let reactionEmojis: [ReactionEmoji] = [
        ReactionEmoji(symbol: "❤️", label: "하트 반응"),
        ReactionEmoji(symbol: "👍🏻", label: "좋아요 반응"),
        ReactionEmoji(symbol: "✅", label: "확인 반응"),
        ReactionEmoji(symbol: "😢", label: "슬픔 반응"),
        ReactionEmoji(symbol: "😆", label: "웃음 반응")
    ]
}

// MARK: - Reaction Emoji

/// 반응 팔레트 한 칸. 고정 목록만 노출해 사용자 자유 입력 경로를 아예 두지 않는다 —
/// 그래서 Genmoji(표준 유니코드가 아닌 이미지 글리프)가 서버로 나갈 수 없다.
fileprivate struct ReactionEmoji: Identifiable {

    let symbol: String
    /// 글리프만 읽히면 무엇을 누르는지 알 수 없어 VoiceOver 용 이름을 따로 들고 다닌다.
    let label: String

    var id: String { symbol }
}

// MARK: - Message Action

/// 말풍선 하나에 걸 수 있는 동작.
///
/// 노출 판정을 ``items(deliveryState:canReport:canDelete:)`` 하나로 모아 둔다 — 뷰 안에서
/// `if` 로 흩어 두면 조건이 맞는지 화면을 띄워 봐야만 알 수 있다.
enum MessageAction: Hashable, Identifiable {
    case reply
    case copy
    case report
    case delete

    var id: Self { self }

    var title: String {
        switch self {
        case .reply: "답장"
        case .copy: "복사"
        case .report: "신고"
        case .delete: "삭제"
        }
    }

    var systemImage: String {
        switch self {
        case .reply: "arrowshape.turn.up.left"
        case .copy: "doc.on.doc"
        case .report: "flag"
        case .delete: "trash"
        }
    }

    /// 신고는 파괴적이지 않다 — 지우는 동작이 아니고, 운영진 권한이라 삭제와 함께 뜨는 자리에서
    /// 빨강이 둘이면 어느 쪽이 되돌릴 수 없는지가 흐려진다.
    var isDestructive: Bool { self == .delete }

    static func items(
        deliveryState: ThreadMessageDeliveryState,
        canReport: Bool,
        canDelete: Bool
    ) -> [MessageAction] {
        var actions: [MessageAction] = []

        // 아직 서버가 모르는 메시지는 답장 대상이 될 수 없다 — 보낼 id 가 내가 만든 UUID 다.
        if deliveryState == .sent { actions.append(.reply) }
        actions.append(.copy)
        if canReport { actions.append(.report) }
        if canDelete { actions.append(.delete) }

        return actions
    }
}

// MARK: - Anchor Key

/// 액션 대상 말풍선의 화면 좌표. 겨냥된 버블 하나만 값을 채우므로 마지막 non-nil 이 곧 정답이다.
struct MessageActionAnchorKey: PreferenceKey {

    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let next = nextValue() { value = next }
    }
}

// MARK: - Layout

/// 떠 있는 레이어의 원점 계산. 뷰에서 떼어 두면 화면을 띄우지 않고도 화면 밖으로 나가는
/// 경우를 잠글 수 있다.
enum MessageActionLayout {

    /// 레이어 하나의 y 원점을 화면 안으로 보정한다.
    static func clampedY(
        preferredY: CGFloat,
        height: CGFloat,
        containerHeight: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        let maxY = containerHeight - margin - height
        // 컨테이너가 레이어보다 작으면 상한이 하한보다 아래로 내려간다 — 그때는 위에 붙인다.
        guard maxY >= margin else { return margin }
        return min(max(preferredY, margin), maxY)
    }

    /// 좌우 정렬 + 화면 밖으로 나가지 않게 x 원점을 정한다.
    static func clampedX(
        isMine: Bool,
        width: CGFloat,
        containerWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        max(isMine ? containerWidth - margin - width : margin, margin)
    }
}

// MARK: - Overlay

/// 롱프레스로 열리는 반응 바 + 컨텍스트 메뉴 (시안 #12306:34643 / #12306:34343).
///
/// 딤에 말풍선 모양 구멍을 뚫어 원본을 그대로 드러낸다. 버블을 한 번 더 그려 얹으면 인용·링크
/// 카드까지 복제해야 하고, 그 복제본이 원본과 어긋나는 순간 눈에 띈다.
struct MessageActionOverlay: View {

    // MARK: - Property

    /// 오버레이 좌표계 기준 말풍선 rect.
    let bubbleFrame: CGRect
    let containerSize: CGSize
    let isMine: Bool
    let actions: [MessageAction]
    let onReact: (String) -> Void
    let onMoreEmoji: () -> Void
    let onAction: (MessageAction) -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AccessibilityFocusState private var isReactionBarFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            dimLayer
            dismissLayer

            GlassEffectContainer {
                ZStack(alignment: .topLeading) {
                    reactionBar
                        .offset(x: reactionBarOrigin.x, y: reactionBarOrigin.y)

                    menuCard
                        .offset(x: menuOrigin.x, y: menuOrigin.y)
                }
                .frame(
                    width: containerSize.width,
                    height: containerSize.height,
                    alignment: .topLeading
                )
            }
            .transition(appearTransition)
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { onDismiss() }
    }

    // MARK: - View Component

    private var dimLayer: some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: containerSize))
            path.addRoundedRect(
                in: bubbleFrame,
                cornerSize: CGSize(
                    width: Constants.bubbleHoleRadius,
                    height: Constants.bubbleHoleRadius
                )
            )
        }
        // even-odd 라 겹친 말풍선 자리만 칠해지지 않는다.
        .fill(Color.black.opacity(Constants.dimOpacity), style: FillStyle(eoFill: true))
        .transition(.opacity)
        .accessibilityHidden(true)
    }

    /// 딤 자체에 제스처를 걸면 구멍 뚫린 자리가 탭을 못 받는다 — 투명 레이어를 따로 얹는다.
    private var dismissLayer: some View {
        Color.clear
            .contentShape(.rect)
            .onTapGesture { onDismiss() }
            .accessibilityHidden(true)
    }

    private var reactionBar: some View {
        HStack(spacing: 0) {
            ForEach(Constants.reactionEmojis) { emoji in
                reactionCell(emoji, isFirst: emoji.id == Constants.reactionEmojis.first?.id)
            }

            Button(action: onMoreEmoji) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: Constants.moreEmojiSize))
                    .foregroundStyle(Color.grey600)
                    .frame(width: Constants.reactionCell, height: Constants.reactionCell)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Constants.moreEmojiLabel)
        }
        .padding(.horizontal, Constants.reactionBarPadding)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    /// 첫 칸에만 포커스를 걸어 VoiceOver 가 오버레이 안에서 시작하게 한다.
    @ViewBuilder
    private func reactionCell(_ emoji: ReactionEmoji, isFirst: Bool) -> some View {
        let cell = Button {
            onReact(emoji.symbol)
        } label: {
            Text(emoji.symbol)
                // 고정 크기로 둔다. Dynamic Type 으로 글리프가 커지면 50pt pitch 가 무너진다.
                .font(.system(size: Constants.emojiSize))
                .frame(width: Constants.reactionCell, height: Constants.reactionCell)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(emoji.label)

        if isFirst {
            cell
                .accessibilityFocused($isReactionBarFocused)
                .onAppear { isReactionBarFocused = true }
        } else {
            cell
        }
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            ForEach(actions) { action in
                menuButton(action)
            }
        }
        .frame(width: Constants.menuWidth)
        .padding(.vertical, Constants.menuVerticalPadding)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: Constants.menuCornerRadius)
        )
    }

    @ViewBuilder
    private func menuButton(_ action: MessageAction) -> some View {
        let button = Button {
            onAction(action)
        } label: {
            menuRow(action)
        }
        .buttonStyle(.plain)

        if action.isDestructive {
            button
                .accessibilityHint(Constants.deleteHint)
                .accessibilityAddTraits(.isButton)
        } else {
            button
        }
    }

    private func menuRow(_ action: MessageAction) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            Image(systemName: action.systemImage)
                .font(.system(size: Constants.menuIconSize))
                .frame(width: Constants.menuIconWidth)

            Text(action.title)

            Spacer(minLength: 0)
        }
        .appFont(.body, color: action.isDestructive ? Color.red500 : Color.grey900)
        .padding(.horizontal, DefaultSpacing.spacing16)
        // 높이를 고정하지 않는다 — Dynamic Type 을 키우면 레이블이 잘린다.
        .frame(maxWidth: .infinity, minHeight: Constants.menuItemHeight)
        .contentShape(.rect)
    }

    // MARK: - Computed Property

    private var reactionBarOrigin: CGPoint {
        CGPoint(
            x: MessageActionLayout.clampedX(
                isMine: isMine,
                width: Constants.reactionBarWidth,
                containerWidth: containerSize.width,
                margin: Constants.margin
            ),
            y: MessageActionLayout.clampedY(
                preferredY: bubbleFrame.minY - Constants.gap - Constants.reactionBarHeight,
                height: Constants.reactionBarHeight,
                containerHeight: containerSize.height,
                margin: Constants.margin
            )
        )
    }

    private var menuOrigin: CGPoint {
        CGPoint(
            x: MessageActionLayout.clampedX(
                isMine: isMine,
                width: Constants.menuWidth,
                containerWidth: containerSize.width,
                margin: Constants.margin
            ),
            y: MessageActionLayout.clampedY(
                preferredY: bubbleFrame.maxY + Constants.gap,
                height: menuHeight,
                containerHeight: containerSize.height,
                margin: Constants.margin
            )
        )
    }

    /// 배치 기준값. 실제 카드는 `minHeight` 로 자라므로 여기서는 보정에 쓸 어림값만 낸다.
    private var menuHeight: CGFloat {
        let itemHeight = dynamicTypeSize.isAccessibilitySize
            ? Constants.menuItemHeight * Constants.accessibilityItemScale
            : Constants.menuItemHeight
        return CGFloat(actions.count) * itemHeight + Constants.menuVerticalPadding * 2
    }

    private var appearTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color.grey100

        MessageActionOverlay(
            bubbleFrame: CGRect(x: 16, y: 320, width: 220, height: 44),
            containerSize: CGSize(width: 393, height: 852),
            isMine: false,
            actions: [.reply, .copy, .report, .delete],
            onReact: { _ in },
            onMoreEmoji: {},
            onAction: { _ in },
            onDismiss: {}
        )
    }
    .ignoresSafeArea()
}
#endif
