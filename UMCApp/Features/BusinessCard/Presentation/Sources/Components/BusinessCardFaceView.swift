//
//  BusinessCardFaceView.swift
//  BusinessCardPresentation
//
//  Created by One on 8/17/26.
//

import BusinessCardDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

/// 시안 `명함_l`(372×205) — 마이페이지 루트가 쓰는 명함 카드.
///
/// #1347 에서 「라이선스 카드」 어법으로 갈아탔다. 레퍼런스(RIFE LICENSE)에서 가져온 것은
/// **레이아웃과 타이포뿐**이다 — 타이틀 · `{파트}. [{이름}]` · 기록 슬롯 4칸 · 하단 발급 행 ·
/// 라틴 대문자 모노스페이스. 배경은 기존 브랜드 그라디언트(`indigo400 → indigo500`)를 그대로
/// 둔다. 다크 단색으로 갈아엎으면 라이트/다크(#1234)·대비(#1235) 기준을 처음부터 다시 잡아야
/// 하는데, 카드가 얻는 건 톤 하나뿐이라 값이 맞지 않는다.
///
/// 앞면은 이름·파트/기수 칩·기록 슬롯·발급 행, 뒷면은 시리얼과 **QR + 외부 링크 3줄**
/// (github · linkedIn · blog)이다. 헤더와 하단 버튼 두 개는 양면 공통이다.
///
/// 상태를 들지 않는다 — 뒤집힘 여부는 소유자가 가지고 ``isFlipped`` 로 내려준다.
/// QR 도 마찬가지로 생성은 UseCase 의 일이라 완성된 이미지를 받는다.
///
/// - Note: 3D 플립 모션은 이 라운드 범위 밖이다(#1348). 두 면을 즉시 전환한다.
public struct BusinessCardFaceView: View {

    // MARK: - Property

    private let card: MyCard
    private let stat: ActivityStat
    private let isFlipped: Bool
    private let qrImage: CGImage?
    private let onFlip: (() -> Void)?
    private let onExchange: (() -> Void)?
    private let onQR: (() -> Void)?

    private enum Constants {
        static let title = "UMC LICENSE"
        static let serialPrefix = "SERIAL. "
        static let exchangeIcon = "shareplay"
        static let exchangeTitle = "명함 교환"
        static let qrIcon = "qrcode"
        static let qrTitle = "QR 코드"
        static let qrLabel = "내 명함 QR 코드"
        static let qrUnavailable = "QR 코드를 만들지 못했어요"
        static let flipIcon = "arrow.2.squarepath"
        static let flipToBack = "명함 뒷면 보기"
        static let flipToFront = "명함 앞면 보기"
    }

    /// 시안 실측값 (`Figma 12639:33234` / `12766:98172`).
    private enum Metrics {
        /// 시안 실측 높이. 글자가 커지면 이 값을 **바닥으로** 두고 늘어난다
        /// (고정하면 AX 크기에서 칩·슬롯이 카드 밖으로 밀린다).
        static let cardMinHeight: CGFloat = 205
        /// 버튼 행(39)과 그 위 간격(24)을 뺀 높이. 액션 없는 카드가 아래를 비우지 않게 한다.
        static let faceOnlyMinHeight: CGFloat = 205 - 24 - 39
        static let cardRadius: CGFloat = 34
        static let cardPadding: CGFloat = 16
        /// 정보 블록과 버튼 행 사이.
        static let blockSpacing: CGFloat = 24
        /// 헤더 행과 그 아래 본문 사이.
        static let headerSpacing: CGFloat = 8
        /// QR 과 오른쪽 링크 블록 사이.
        static let contentSpacing: CGFloat = 16
        /// 앞면 블록(이름 행 · 칩 행 · 기록 슬롯 · 발급 행) 사이. 네 블록이 205pt 안에
        /// 들어오도록 ``contentSpacing`` 보다 좁게 잡는다.
        static let faceBlockSpacing: CGFloat = 12
        static let qrSize: CGFloat = 70
        static let nameSpacing: CGFloat = 6
        static let chipSpacing: CGFloat = 5
        static let logoWidth: CGFloat = 47
        static let logoHeight: CGFloat = 15.16
        static let buttonSpacing: CGFloat = 10
        static let buttonMinHeight: CGFloat = 39
        static let buttonRadius: CGFloat = 40
        static let buttonIconSize: CGFloat = 19
        static let linkSpacing: CGFloat = 8
        static let linkIconSize: CGFloat = 18
        static let qrRadius: CGFloat = 6.18
        static let qrBorderWidth: CGFloat = 0.26
        /// 라이선스 어법의 넓은 자간. 고정값이라 AX 크기에서는 상대적으로 좁아지는데,
        /// 그쪽에서는 자간보다 슬롯 4칸이 들어갈 폭이 급하므로 의도한 방향이다.
        static let tracking: CGFloat = 1.2
        static let slotSpacing: CGFloat = 16
        static let slotLabelSpacing: CGFloat = 2
        /// 「BOOKMARK」처럼 긴 라벨이 잘려 뜻이 사라지느니 살짝 줄인다 (`PartChip` 선례).
        static let slotMinimumScale: CGFloat = 0.8
        static let dividerHeight: CGFloat = 1
        /// 발급 행 구분선. 텍스트가 아니라 구획선이라 흰색을 그대로 쓰면 카드가 갈라져 보인다.
        static let dividerOpacity: CGFloat = 0.35
    }

    /// 카드 배경 · QR 테두리. 전부 코어 토큰이다 (#1237).
    ///
    /// 시안 실측은 `linear-gradient(112.185deg, rgba(114,142,253,0.8), #5468FC)` ·
    /// 테두리 `#E5E8ED` 였고 그동안 `BusinessCardPalette` 가 그 raw 값을 들고 있었다.
    /// 같은 화면의 버튼이 `Color.indigo500`(#4869F0)을 쓰는 바람에 파랑이 둘로
    /// 갈렸고, raw 값에는 다크 모드 대응이 없었다. 토큰은 Asset Catalog 라 모드별
    /// 값을 스스로 들고 있으므로 명함도 토큰으로 수렴한다.
    /// (실측과의 차: 시작색 #728EFD→#6683FF · 끝색 #5468FC→#4869F0 · 테두리 #E5E8ED→#E7E8EA)
    private enum Palette {
        static let gradientStart = Color.indigo400
        static let gradientEnd = Color.indigo500
        static let qrBorder = Color.grey200
    }

    // MARK: - Init

    /// - Parameter stat: 기록 슬롯 4칸에 실을 카운트. 기본값 ``ActivityStat/empty`` 는 네 칸이
    ///   모두 "-" 가 된다 — 받은 명함(상대 카드)에는 상대의 카운트가 아예 없으므로 그게
    ///   정확한 표현이다(「0건」이 아니라 「우리가 못 셌다」, #1222).
    public init(
        card: MyCard,
        stat: ActivityStat = .empty,
        isFlipped: Bool = false,
        qrImage: CGImage? = nil,
        onFlip: (() -> Void)? = nil,
        onExchange: (() -> Void)? = nil,
        onQR: (() -> Void)? = nil
    ) {
        self.card = card
        self.stat = stat
        self.isFlipped = isFlipped
        self.qrImage = qrImage
        self.onFlip = onFlip
        self.onExchange = onExchange
        self.onQR = onQR
    }

    // MARK: - Body

    /// 액션이 하나도 없으면 버튼 행을 그리지 않는다 — 받은 명함 상세(#1227)에는
    /// 「명함 교환」·「QR 코드」가 할 일이 없다. 눌러도 아무 일 없는 버튼을 두느니 뺀다.
    private var hasActions: Bool {
        onExchange != nil || onQR != nil
    }

    public var body: some View {
        VStack(spacing: Metrics.blockSpacing) {
            VStack(alignment: .leading, spacing: Metrics.headerSpacing) {
                header
                if isFlipped { backFace } else { frontFace }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if hasActions { actionButtons }
        }
        .padding(Metrics.cardPadding)
        .frame(maxWidth: .infinity)
        .frame(minHeight: hasActions ? Metrics.cardMinHeight : Metrics.faceOnlyMinHeight)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius))
    }

    // MARK: - View Component

    /// 시안은 좌하단→우상단 112.185°다. 372×205 카드에서 대각선은 약 119°라
    /// 눈으로 구분되지 않는 차이 안에 들어온다 — 각도를 직접 계산하지 않는다.
    private var cardBackground: some View {
        LinearGradient(
            colors: [Palette.gradientStart.opacity(0.8), Palette.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(spacing: 0) {
            HStack(spacing: Metrics.linkSpacing) {
                Image.umcWordmark
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.logoWidth, height: Metrics.logoHeight)
                    // 옆의 타이틀 텍스트가 같은 뜻을 말한다 — 중복 낭독 방지.
                    .accessibilityHidden(true)

                licenseText(Constants.title)
            }

            Spacer(minLength: Metrics.linkSpacing)

            flipButton
        }
    }

    @ViewBuilder
    private var flipButton: some View {
        if onFlip != nil { flipButtonBody }
    }

    private var flipButtonBody: some View {
        CardGlassCircleButton(
            systemName: Constants.flipIcon,
            label: isFlipped ? Constants.flipToFront : Constants.flipToBack
        ) {
            onFlip?()
        }
        .accessibilityLabel(isFlipped ? Constants.flipToFront : Constants.flipToBack)
    }

    /// 레퍼런스에 있던 두 요소는 의도적으로 빼 뒀다. 되살리기 전에 근거부터 확인할 것:
    /// **QR 은 뒷면에 그대로 둔다** — 앞면 우상단은 플립 버튼 자리고, 양면에 QR 을 두면
    /// 같은 값이 두 번 나올 뿐이다. **호(arc) 게이지도 그리지 않는다** — 대응하는 진척률이
    /// 도메인에 없어서 그리는 순간 없는 수치를 지어내게 된다.
    private var frontFace: some View {
        VStack(alignment: .leading, spacing: Metrics.faceBlockSpacing) {
            identityRow

            HStack(spacing: Metrics.chipSpacing) {
                PartChip(text: card.partDisplayName)
                PartChip(text: "\(card.generation)기")
            }

            recordSlots
            issuerRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 이름·칩·슬롯 8개가 따로 읽히면 누구 명함인지 조립해야 알 수 있다.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.frontFaceAccessibilityLabel(stat: stat))
    }

    /// 레퍼런스 어법 `Runner. [한수빈]` 을 그대로 옮긴 이름 행.
    ///
    /// 파트는 **대문자로 올리지 않는다** — `iOS` 가 `IOS` 가 되면 틀린 파트명이 된다.
    /// 레퍼런스도 대문자는 타이틀과 슬롯 라벨에만 쓴다.
    ///
    /// 이름은 한글이라 모노 대상이 아니므로 Pretendard 를 유지한다. 표기 규칙은
    /// ``MyCard/nameWithNickname``(#1236) 한 곳에 있고, 폭이 모자라면 파트가 먼저
    /// 줄어들도록 이름에 우선순위를 준다 — 이름이 1차 식별자다.
    private var identityRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.nameSpacing) {
            licenseText("\(card.partDisplayName).", style: .title3, weight: .semibold)
                .lineLimit(1)

            Text("[\(card.nameWithNickname)]")
                .appFont(.title3, weight: .semibold, color: Color.white)
                .lineLimit(1)
                .layoutPriority(1)
        }
    }

    /// 기록 슬롯 4칸.
    ///
    /// 기본은 한 줄(1×4)이지만 모노 + 대문자 + 넓은 자간은 같은 폭에 글자가 덜 들어간다 —
    /// AX 글자 크기에서 「BOOKMARK」 한 칸만 100pt를 넘어 네 칸이 카드 밖으로 밀린다.
    /// `ViewThatFits` 가 그때 2×2 로 접는다 (#1234 — 카드는 늘어나되 넘치지 않는다).
    private var recordSlots: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Metrics.slotSpacing) {
                ForEach(CardRecordSlot.allCases, id: \.self) { recordSlot($0) }
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: Metrics.slotSpacing,
                verticalSpacing: Metrics.slotSpacing
            ) {
                GridRow {
                    recordSlot(.study)
                    recordSlot(.activity)
                }
                GridRow {
                    recordSlot(.cards)
                    recordSlot(.bookmark)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recordSlot(_ slot: CardRecordSlot) -> some View {
        VStack(alignment: .leading, spacing: Metrics.slotLabelSpacing) {
            licenseText(slot.label, style: .caption2)
            licenseText(slot.displayValue(in: stat), style: .callout, weight: .semibold)
        }
        .lineLimit(1)
        .minimumScaleFactor(Metrics.slotMinimumScale)
    }

    /// 하단 발급 행 — 발급 기관 자리에 소속 대학교가 온다.
    ///
    /// 레퍼런스의 `ISSUED / 2026 . 09 . 10` 에 해당하는 **발급일은 싣지 않는다.**
    /// ``MyCard`` 에 그 필드가 없고(서버 요구사항은 #1225), 클라이언트에서 오늘 날짜 따위로
    /// 지어내면 카드가 매번 다른 날 발급된 것처럼 읽힌다. 플레이스홀더(`----.--.--`)도 두지
    /// 않는다 — 빈 자리가 「곧 채워질 값」처럼 보이는 것 자체가 거짓말이다.
    /// 서버 필드가 생기면 이 행 오른쪽에 붙이면 된다.
    private var issuerRow: some View {
        VStack(alignment: .leading, spacing: Metrics.linkSpacing) {
            Rectangle()
                .fill(Color.white.opacity(Metrics.dividerOpacity))
                .frame(height: Metrics.dividerHeight)

            // 한글이라 모노·대문자 대상이 아니다. 자간만 라이선스 어법에 맞춘다.
            Text(card.university)
                .appFont(.caption1, color: Color.white)
                .tracking(Metrics.tracking)
                .lineLimit(1)
        }
    }

    /// 뒷면은 시리얼 한 줄 아래에 QR 과 링크 3줄이 온다.
    private var backFace: some View {
        VStack(alignment: .leading, spacing: Metrics.linkSpacing) {
            licenseText(Constants.serialPrefix + card.licenseSerial)

            HStack(alignment: .top, spacing: Metrics.contentSpacing) {
                qrThumbnail

                VStack(alignment: .leading, spacing: Metrics.linkSpacing) {
                    // github·linkedIn 은 시안 브랜드 SVG(18×18, 흰색 모노).
                    // blog 만 시안도 SF Symbol `link` 다.
                    linkRow(value: card.github) { brandIcon(Image.githubMono) }
                    linkRow(value: card.linkedIn) { brandIcon(Image.linkedInMono) }
                    linkRow(value: card.blog) { symbolIcon("link") }
                }

                Spacer(minLength: 0)
            }
        }
    }

    /// 시안 70×70 흰 박스 · radius 6.18 · 0.26pt 테두리.
    @ViewBuilder
    private var qrThumbnail: some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.qrRadius)

        Group {
            if let qrImage {
                Image(decorative: qrImage, scale: 1)
                    // QR 은 확대해도 흐려지면 안 된다 — 보간을 끈다.
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(Metrics.linkSpacing)
            } else {
                Color.clear
            }
        }
        .frame(width: Metrics.qrSize, height: Metrics.qrSize)
        // QR 은 어느 모드에서도 흰 바탕이어야 인식된다 — 여기만 토큰을 쓰지 않는다.
        .background(Color.white, in: shape)
        .overlay { shape.stroke(Palette.qrBorder, lineWidth: Metrics.qrBorderWidth) }
        .accessibilityElement()
        .accessibilityLabel(qrImage == nil ? Constants.qrUnavailable : Constants.qrLabel)
    }

    /// 값이 없어도 줄을 지운다 — 시안이 3줄 고정이지만 빈 줄은 서버 미입력을
    /// 링크가 있는 것처럼 보이게 한다.
    @ViewBuilder
    private func linkRow(
        value: String?,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .bottom, spacing: Metrics.linkSpacing) {
                icon()

                Text(value)
                    .appFont(.footnote, color: Color.white)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// 브랜드 SVG 아이콘(에셋 원본이 흰색이라 틴트 없이 크기만 잡는다).
    ///
    /// VoiceOver 에는 숨긴다 — 링크 값 텍스트가 바로 옆에 있어 에셋 이름까지 읽으면
    /// "githubMono, github.com/umc" 처럼 겹쳐 들린다.
    private func brandIcon(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: Metrics.linkIconSize, height: Metrics.linkIconSize)
            .accessibilityHidden(true)
    }

    /// SF Symbol 아이콘 — 브랜드 아이콘과 같은 18×18 틀에 맞춘다.
    private func symbolIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: AppFont.footnote.size))
            .foregroundStyle(Color.white)
            .frame(width: Metrics.linkIconSize, height: Metrics.linkIconSize)
    }

    /// 라이선스 어법 텍스트 — **시스템 모노스페이스 + 넓은 자간**.
    ///
    /// 서체를 번들에 새로 들이지 않는다(라이선스 확인·폰트 등록이 따라온다). 대신 크기는
    /// `AppFont` 의 `textStyle` 을 그대로 태워 Dynamic Type 을 따라가게 한다 — 고정 pt 로
    /// 박으면 이 카드만 글자 크기 설정을 무시한다.
    ///
    /// 라틴 대문자·숫자 전용이다. 한글은 모노 패밀리가 없어 어차피 시스템 폰트로 떨어지므로
    /// 이름·학교는 Pretendard(`appFont`)를 그대로 쓴다.
    private func licenseText(
        _ text: String,
        style: AppFont = .caption2,
        weight: Font.Weight = .regular
    ) -> some View {
        Text(text)
            .font(.system(style.textStyle, design: .monospaced, weight: weight))
            .tracking(Metrics.tracking)
            // 인디고 그라디언트 위에서 4.5:1 을 넘는 유일하게 안전한 값이라 흰색을 고정한다.
            // 라벨·값을 opacity 로 구분하면 그 순간 대비가 3점대로 떨어진다 (#1235).
            .foregroundStyle(Color.white)
    }

    private var actionButtons: some View {
        HStack(spacing: Metrics.buttonSpacing) {
            actionButton(
                icon: Constants.exchangeIcon,
                title: Constants.exchangeTitle,
                action: onExchange
            )
            actionButton(icon: Constants.qrIcon, title: Constants.qrTitle, action: onQR)
        }
    }

    /// 시안 165×39 · radius 40 — 두 버튼이 카드 폭을 균등 분할한다.
    private func actionButton(
        icon: String,
        title: String,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Metrics.buttonSpacing) {
                Image(systemName: icon)
                    .font(.system(size: Metrics.buttonIconSize))

                Text(title)
                    .appFont(.subheadline, weight: .semibold)
            }
            // 시안 변수 main-color/indigo500 = 코어 토큰. 카드 그라디언트도 같은
            // 토큰으로 수렴해(#1237) 이제 한 화면에 파랑이 하나뿐이다.
            .foregroundStyle(Color.indigo500)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Metrics.buttonMinHeight)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Metrics.buttonRadius))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("앞면") {
    BusinessCardFaceView(
        card: BusinessCardPreviewData.myCard,
        stat: BusinessCardPreviewData.activityStat
    )
    .padding(.horizontal, 14)
    .frame(maxHeight: .infinity)
    .background(Color.grey100)
}

/// 받은 명함(상대 카드)과 조회 실패가 보는 화면 — 기록 슬롯 네 칸이 모두 "-" 다.
#Preview("앞면 · 못 센 상태") {
    BusinessCardFaceView(card: BusinessCardPreviewData.myCard)
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
        .background(Color.grey100)
}

#Preview("뒷면") {
    BusinessCardFaceView(card: BusinessCardPreviewData.myCard, isFlipped: true)
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
        .background(Color.grey100)
}
#endif
