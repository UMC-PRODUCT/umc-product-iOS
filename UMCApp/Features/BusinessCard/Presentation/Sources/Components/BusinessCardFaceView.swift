//
//  BusinessCardFaceView.swift
//  BusinessCardPresentation
//
//  Created by One on 8/17/26.
//

import BusinessCardDomain
import CoreDesignSystem
import CoreUIComponents
import Foundation
import SwiftUI

/// 시안 `명함_l`(372×205) — 마이페이지 루트가 쓰는 명함 카드.
///
/// #1347 에서 「라이선스 카드」 어법으로 갈아탔다. 레퍼런스(RIFE LICENSE)에서 가져온 것은
/// **레이아웃과 타이포뿐**이다 — 타이틀 · 이름 아래 파트 · 하단 발급 행 ·
/// 라틴 모노스페이스. 배경은 기존 브랜드 그라디언트(`indigo400 → indigo500`)를 그대로
/// 둔다. 다크 단색으로 갈아엎으면 라이트/다크(#1234)·대비(#1235) 기준을 처음부터 다시 잡아야
/// 하는데, 카드가 얻는 건 톤 하나뿐이라 값이 맞지 않는다.
///
/// 앞면은 이름 행·파트 행·발급 행(학교 · 기수), 뒷면은 시리얼과 **QR + 외부 링크 3줄**
/// (github · linkedIn · blog)이다. 헤더와 하단 버튼 두 개는 양면 공통이다.
///
/// 상태를 들지 않는다 — 뒤집힘 여부는 소유자가 가지고 ``isFlipped`` 로 내려준다.
/// QR 도 마찬가지로 생성은 UseCase 의 일이라 완성된 이미지를 받는다.
///
/// 면 전환은 Y축 원근 회전이다(#1348). ``CardFlip`` 이 90° 에서 면을 갈아 끼우고 뒷면을
/// 미리 반 바퀴 돌려 둬 거울상을 막는다. 「동작 줄이기」가 켜져 있으면 회전 없이 바뀐다.
public struct BusinessCardFaceView: View {

    // MARK: - Property

    private let card: MyCard
    private let isFlipped: Bool
    private let qrImage: CGImage?
    private let onFlip: (() -> Void)?
    private let onExchange: (() -> Void)?
    private let onQR: (() -> Void)?

    /// 회전은 사용자가 만들지 않은 자율 모션이라 이 설정이 이긴다.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Constants {
        static let title = "UMC LICENSE"
        static let serialPrefix = "SERIAL. "
        static let generationPrefix = "GEN. "
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
        /// (고정하면 AX 크기에서 이름·파트 행이 카드 밖으로 밀린다).
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
        /// 앞면 블록(이름·파트 행 · 발급 행) 사이.
        static let faceBlockSpacing: CGFloat = 12
        static let qrSize: CGFloat = 70
        /// 이름 행과 파트 행 사이.
        static let nameSpacing: CGFloat = 6
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
        /// 그쪽에서는 자간보다 한 줄에 글자가 들어갈 폭이 급하므로 의도한 방향이다.
        static let tracking: CGFloat = 1.2
        static let dividerHeight: CGFloat = 1
        /// 발급 행 구분선. 텍스트가 아니라 구획선이라 흰색을 그대로 쓰면 카드가 갈라져 보인다.
        static let dividerOpacity: CGFloat = 0.35

        // MARK: 플립 (#1348)

        /// 회전축. 세로축이라 카드가 책장처럼 좌우로 넘어간다.
        static let flipAxis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)

        /// 플립 지속(초). #1349 가 철거한 3D 스택이 쓰던 값에서 시작한다 — 180° 는 복귀
        /// 모션의 6배 이동인데 1.5배만 준다. 각속도 지각이 선형이 아니라 6배를 그대로
        /// 주면 늘어지게 느껴진다. **최종값은 디자인팀 확인 항목**(#1348).
        static let flipDuration: TimeInterval = 0.45

        /// 원근 계수. SwiftUI 는 이 값으로 시점 거리 ≈ `카드 폭 / perspective` 를 만든다.
        /// 0.5 는 카드 폭(≈345pt)의 두 배 거리에서 보는 셈이라 90° 부근에서 가까운 모서리가
        /// 넓어지는 사다리꼴이 눈에 들어오면서, 기본값 1.0 처럼 카드가 휘어 보이지는 않는다.
        /// 레퍼런스(RIFE LICENSE)와 눈으로 맞출 손잡이다.
        static let flipPerspective: CGFloat = 0.5

        /// 정지 상태 그림자 — **디자인팀 확인 항목**(#1348). 시안에 명함 그림자가 없어서
        /// 회전과 함께 여기서 처음 생긴다. 같은 피처의 `CardQRView` 흰 박스가 쓰는 값
        /// (검정 8% · 반경 16 · 아래 4)을 그대로 가져왔다 — 두 화면 다 `grey000` 바탕에서
        /// 카드 한 장이 떠 보이면 되는 같은 문제다.
        static let shadowRadius: CGFloat = 16
        static let shadowOffsetY: CGFloat = 4
        static let shadowOpacity: Double = 0.08

        /// 회전 중 그림자가 좌우로 쓸리는 최대 폭. 회전축이 세로라 가로로만 쓸린다.
        /// 정지 오프셋(4)의 3배 — 카드가 떠 있다는 게 보일 만큼은 크되, 카드 폭 밖으로
        /// 빠져나가 따로 노는 얼룩이 되지는 않는 선이다.
        static let shadowSway: CGFloat = 12
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
        /// 회전 그림자. 토큰(`grey900`)이 아니라 검정인 이유는 같은 피처의 `CardQRView`
        /// 와 맞추기 위해서다 — 바탕을 눌러 카드를 띄우는 역할만 한다.
        static let shadow = Color.black
    }

    // MARK: - Init

    public init(
        card: MyCard,
        isFlipped: Bool = false,
        qrImage: CGImage? = nil,
        onFlip: (() -> Void)? = nil,
        onExchange: (() -> Void)? = nil,
        onQR: (() -> Void)? = nil
    ) {
        self.card = card
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
        CardFlip(
            angle: isFlipped ? CardFlipGeometry.halfTurn : 0,
            content: cardBody(showsBack:)
        )
        // 회전을 만드는 유일한 지점. 「동작 줄이기」면 `nil` 이라 각도가 즉시 튀고, 그 결과가
        // 회전 없는 면 교체 — 이 파일이 원래 하던 동작 그대로다.
        .animation(
            reduceMotion ? nil : .easeInOut(duration: Metrics.flipDuration),
            value: isFlipped
        )
    }

    /// 회전하는 몸통. 헤더와 버튼 행은 양면 공통이지만 면과 **함께** 돈다 — 카드 한 장이
    /// 넘어가는 것이지 앞면 위에서 내용만 갈리는 것이 아니다.
    ///
    /// 회전은 `rotation3DEffect`(렌더 단계)라 레이아웃을 건드리지 않는다. 90° 에서 면이
    /// 바뀌어도 안 보이는 면이 `.hidden()` 으로 자리를 잡고 있어 카드 높이는 늘 두 면 중
    /// 큰 쪽이고, 아래 섹션이 움직이지 않는다(#1363). 낮은 면은 위에 붙고 남는 공간은 아래다.
    /// 고정 높이·비율로 맞추지 않는 건 AX 크기에서 면이 카드 밖으로 넘치기 때문이다(#1234).
    ///
    /// 그리는 면은 여전히 하나다(``CardFlip``). 분기를 `if/else` 로 둬 90° 교체의 identity
    /// 동작도 이전과 같다.
    private func cardBody(showsBack: Bool) -> some View {
        VStack(spacing: Metrics.blockSpacing) {
            VStack(alignment: .leading, spacing: Metrics.headerSpacing) {
                header

                ZStack(alignment: .topLeading) {
                    if showsBack {
                        frontFace.hidden().accessibilityHidden(true)
                        backFace
                    } else {
                        frontFace
                        backFace.hidden().accessibilityHidden(true)
                    }
                }
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
    ///
    /// #1363 에서 둘을 더 뺐다. **기록 슬롯 4칸** — 마이페이지에서는 카드 바로 아래 섹션이
    /// 같은 카운트를 다시 보여 주고, 받은 명함 상세에서는 상대 카운트가 없어 늘 `-` 였다.
    /// **파트 칩** — 이름 행에 있던 파트와 같은 값을 한 번 더 말할 뿐이었다.
    ///
    /// #1374 에서 **기수 칩**도 뺐다. 기수는 발급 행 오른쪽 `GEN. {기수}` 로 옮겨 한 줄을
    /// 줄였다 — 칩과 학교가 각각 한 줄씩 차지해 카드 오른쪽 절반이 비어 있었다.
    private var frontFace: some View {
        VStack(alignment: .leading, spacing: Metrics.faceBlockSpacing) {
            identityBlock
            issuerRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // 이름·파트·학교·기수가 따로 읽히면 누구 명함인지 조립해야 알 수 있다.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.frontFaceAccessibilityLabel)
    }

    /// 이름 행 아래에 파트 행을 둔다 (#1374).
    ///
    /// 예전에는 레퍼런스 어법 `Runner. [한수빈]` 대로 `{파트}. [{이름}]` 한 줄이었다.
    /// 파트가 먼저 읽혔고, 이름에 우선순위가 걸려 있어 긴 파트명이 잘렸다. 이름이 1차
    /// 식별자라 한 줄을 통째로 주고 가장 크게 그린다.
    ///
    /// 이름은 한글이라 모노 대상이 아니므로 Pretendard 를 유지한다. 표기 규칙은
    /// ``MyCard/nameWithNickname``(#1236) 한 곳에 있다.
    ///
    /// 파트는 **대문자로 올리지 않는다** — `iOS` 가 `IOS` 가 되면 틀린 파트명이 된다.
    /// 줄 수도 막지 않는다. 기본 크기에서는 가장 긴 `Mobile Product Engineer` 도 375pt
    /// 기기에서 한 줄에 들어가고, 큰 글자에서는 말줄임 대신 줄을 바꿔 카드가 늘어난다.
    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: Metrics.nameSpacing) {
            Text(card.nameWithNickname)
                .appFont(.title3, weight: .semibold, color: Color.white)
                .lineLimit(1)

            licenseText(card.partDisplayName, style: .subheadline, weight: .medium)
        }
    }

    /// 하단 발급 행 — 왼쪽 발급 기관 자리에 소속 대학교, 오른쪽에 기수 `GEN. {기수}` 가 온다.
    ///
    /// 오른쪽은 레퍼런스의 `ISSUED / 2026 . 09 . 10` 자리지만 **발급일은 싣지 않는다.**
    /// ``MyCard`` 에 그 필드가 없고(서버 요구사항은 #1225), 클라이언트에서 오늘 날짜 따위로
    /// 지어내면 카드가 매번 다른 날 발급된 것처럼 읽힌다. 비워 둔 그 자리에 기수를 옮겨
    /// 왔다(#1374) — 「몇 기에 발급된 카드인가」라 뜻도 맞는다.
    ///
    /// 폭이 모자라면 학교가 먼저 말줄임된다. 기수는 짧고, 잘리면 숫자가 통째로 사라진다.
    private var issuerRow: some View {
        VStack(alignment: .leading, spacing: Metrics.linkSpacing) {
            Rectangle()
                .fill(Color.white.opacity(Metrics.dividerOpacity))
                .frame(height: Metrics.dividerHeight)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // 한글이라 모노·대문자 대상이 아니다. 자간만 라이선스 어법에 맞춘다.
                Text(card.university)
                    .appFont(.caption1, color: Color.white)
                    .tracking(Metrics.tracking)
                    .lineLimit(1)

                Spacer(minLength: Metrics.linkSpacing)

                licenseText(Constants.generationPrefix + card.generation)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
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
    /// 라틴 문자·숫자 전용이다. 한글은 모노 패밀리가 없어 어차피 시스템 폰트로 떨어지므로
    /// 이름·학교는 Pretendard(`appFont`)를 그대로 쓴다. 파트가 여기 들어오는 것도 명함의
    /// 파트명이 전부 영문이라서다(``MyCard/partDisplayName``, #1374). 못 읽은 원본 파트만
    /// 한글일 수 있는데, 그때도 시스템 폰트로 떨어질 뿐 깨지지는 않는다.
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

    // MARK: - Flip

    /// 카드를 Y축으로 돌리며 90° 에서 면을 갈아 끼우는 컨테이너 (#1348).
    ///
    /// `Animatable` 이라 ``angle`` 에 **프레임마다 보간된 값**이 들어온다. `@State` +
    /// `withAnimation` 으로는 안 된다 — 그쪽 `body` 는 최종값(180)만 보므로 면이 회전
    /// 시작과 동시에 바뀌어 버린다. 90° 판정을 하려면 중간 각도를 봐야 한다.
    ///
    /// 두 면을 겹쳐 그리지 않는다. `ZStack` + `opacity` 로 가르면 교차 구간에서 두 면이
    /// 한 프레임이라도 섞이는데, 여기서는 그릴 면 자체가 하나뿐이다. 안 보이는 면은
    /// `.hidden()` 으로 레이아웃 자리만 잡는다(#1363).
    ///
    /// 목표 각도가 ``BusinessCardFaceView/isFlipped`` 에서 파생된 0 또는 180 뿐이라
    /// 각이 쌓이지 않는다 — 회전 중 다시 누르면 현재 각도에서 반대쪽으로 되돌아간다.
    private struct CardFlip<Content: View>: View, Animatable {

        // MARK: - Property

        var angle: Double
        let content: (Bool) -> Content

        var animatableData: Double {
            get { angle }
            set { angle = newValue }
        }

        // MARK: - Body

        var body: some View {
            let geometry = CardFlipGeometry(angle: angle)

            content(geometry.showsBack)
                // 뒷면을 미리 반 바퀴 돌려 둔다. 바깥 회전과 합쳐 360° 가 되므로 회전이
                // 끝난 뒷면의 텍스트·QR 이 거울상이 아니라 정방향으로 읽힌다.
                .rotation3DEffect(.degrees(geometry.counterTurn), axis: Metrics.flipAxis)
                .rotation3DEffect(
                    .degrees(angle),
                    axis: Metrics.flipAxis,
                    perspective: Metrics.flipPerspective
                )
                // 회전 **뒤에** 얹는다. 앞에 얹으면 그림자가 카드와 함께 뒤집혀 반대쪽으로
                // 뻗는다. 모서리를 보일수록(`facing` → 0) 옅어지고 바닥에 붙는다.
                .shadow(
                    color: Palette.shadow.opacity(Metrics.shadowOpacity * geometry.facing),
                    radius: Metrics.shadowRadius,
                    x: Metrics.shadowSway * CGFloat(geometry.sway),
                    y: Metrics.shadowOffsetY * CGFloat(geometry.facing)
                )
        }
    }
}

/// 플립 한 프레임의 기하 (#1348). 각도 하나에서 「어느 면을 그리는지 · 거울상을 되돌릴
/// 각 · 그림자가 얼마나 정면인지」가 전부 파생된다.
///
/// 뷰에서 떼어 둔 이유는 `CardInteractionPolicy` 와 같다 — 순수 값이라 뷰를 띄우지 않고
/// 테스트된다. 90° 교체와 거울상 방지는 조용히 틀려도 빌드가 통과하는 종류의 규칙이다.
struct CardFlipGeometry {

    // MARK: - Property

    /// 반 바퀴. 앞면과 뒷면이 한 바퀴를 절반씩 나눠 갖는다.
    static let halfTurn: Double = 180

    let angle: Double

    /// 90° 를 **넘는 순간** 뒷면으로 바뀐다. 그 지점의 카드는 폭이 0(`cos 90° = 0`)이라
    /// 교체가 어느 프레임에도 보이지 않는다.
    var showsBack: Bool { angle >= Self.halfTurn / 2 }

    /// 뒷면을 미리 되돌려 두는 각. 바깥 회전과 더해 360° 가 되면 정방향이다.
    var counterTurn: Double { showsBack ? Self.halfTurn : 0 }

    /// 정면도. 1 이면 카드가 정면, 0 이면 모서리만 보인다.
    var facing: Double { abs(cos(radians)) }

    /// 그림자가 좌우로 쓸리는 정도(-1…1). 세로축 회전이라 가로로만 쓸린다.
    var sway: Double { sin(radians) }

    private var radians: Double { angle * .pi / Self.halfTurn }
}

#if DEBUG
#Preview("앞면") {
    BusinessCardFaceView(card: BusinessCardPreviewData.myCard)
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
        .background(Color.grey100)
}

/// 플립 모션(#1348) 확인용 — 버튼을 눌러 회전을 본다. 「동작 줄이기」를 켜 두면 같은
/// 프리뷰가 회전 없이 즉시 바뀐다.
#Preview("플립") {
    @Previewable @State var isFlipped = false

    BusinessCardFaceView(
        card: BusinessCardPreviewData.myCard,
        isFlipped: isFlipped,
        onFlip: { isFlipped.toggle() }
    )
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
