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
import UIKit

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
/// 면 상태는 들지 않는다 — 뒤집힘 여부의 정본은 소유자이고 ``isFlipped`` 로 내려준다.
/// 뷰가 드는 것은 **진행 중인 회전 각도뿐**이다. 끄는 손가락·관성은 소유자가 알 필요가 없고,
/// 면이 달라지는 순간에만 ``onFlip`` 으로 토글을 요청한다.
/// QR 도 마찬가지로 생성은 UseCase 의 일이라 완성된 이미지를 받는다.
///
/// 면 전환은 Y축 원근 회전이다(#1348). ``CardFlip`` 이 면 경계에서 면을 갈아 끼우고 뒷면을
/// 미리 반 바퀴 돌려 둬 거울상을 막는다. #1390 부터 헤더 버튼 대신 카드를 가로로 끌어
/// 돌린다 — 끄는 동안 각이 손가락을 따라가고, 놓으면 속도만큼 더 돌다 가까운 면에 선다.
/// 「동작 줄이기」가 켜져 있으면 회전 없이 한 번만 뒤집힌다.
public struct BusinessCardFaceView: View {

    // MARK: - Property

    private let card: MyCard
    private let isFlipped: Bool
    private let qrImage: CGImage?
    private let onFlip: (() -> Void)?
    private let onExchange: (() -> Void)?
    private let onQR: (() -> Void)?

    /// 누적 각(°). 여러 바퀴 돌면 360 을 넘고 왼쪽으로 돌리면 음수다 — 면 판정은
    /// ``CardFlipGeometry`` 가 정규화한다.
    @State private var angle: Double
    /// 드래그를 잡은 순간의 각. 끄는 동안의 각은 여기에 이동량만 더한다.
    @State private var dragStartAngle: Double = 0
    /// 진행 중인 관성 스핀. 도중에 다시 잡으면 지금 보이는 각을 여기서 역산한다 —
    /// 애니메이션 중인 `angle` 은 이미 도착 각이라 그대로 쓰면 카드가 튄다.
    @State private var spin: Spin?

    /// 관성 스핀은 손을 뗀 뒤 저절로 도는 모션이라 이 설정이 이긴다. 끄는 동안 따라
    /// 도는 것도 막는다 — 큰 3D 회전은 손이 만든 것이라도 어지러움을 부른다.
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
        static let flipToBack = "명함 뒷면 보기"
        static let flipToFront = "명함 앞면 보기"
    }

    /// 시안 실측값 (`Figma 12639:33234` / `12766:98172`).
    private enum Metrics {
        /// 시안 실측(205)보다 키운 높이(#1401) — 콘텐츠가 가장자리에 붙어 답답해 보였다.
        /// 글자가 커지면 이 값을 **바닥으로** 두고 늘어난다
        /// (고정하면 AX 크기에서 이름·파트 행이 카드 밖으로 밀린다).
        static let cardMinHeight: CGFloat = 240
        /// 버튼 행과 그 위 간격을 뺀 높이. 액션 없는 카드가 아래를 비우지 않게 한다.
        static let faceOnlyMinHeight: CGFloat = cardMinHeight - blockSpacing - buttonMinHeight
        static let cardRadius: CGFloat = 34
        /// 시안(16)보다 넓힌 상하좌우 여백(#1401).
        static let cardPadding: CGFloat = 24
        /// 정보 블록과 버튼 행 사이.
        static let blockSpacing: CGFloat = 24
        /// 헤더 행과 그 아래 본문 사이. 여백을 넓힌 만큼 함께 벌린다(#1401).
        static let headerSpacing: CGFloat = 12
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

        /// 바깥에서 면을 바꿀 때(VoiceOver 액션) 반 바퀴 플립 지속(초).
        /// #1349 가 철거한 3D 스택이 쓰던 값에서 시작한다 — 180° 는 복귀
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

        // MARK: 드래그 회전 (#1390)

        /// 손가락 1pt 당 회전 각(°). 카드 폭(≈360pt)을 끝까지 끌면 반 바퀴다 — 손 밑의
        /// 표면이 손가락을 대략 따라오는 비율. 손맛을 맞출 손잡이다.
        static let dragDegreesPerPoint: Double = 0.5

        /// 놓는 순간 속도로 더 가는 시간(초). `UIScrollView` 감속처럼 세게 튕길수록 멀리
        /// 가고, 그 투영 각에서 가장 가까운 면에 선다. 상한이 없어 세게 튕기면 여러 바퀴 돈다.
        static let momentumProjection: Double = 0.35

        /// 관성 감속 곡선의 시작 제어점. 끝 제어점과 함께 ease-out cubic 이다.
        static let spinStartControl = UnitPoint(x: 0.33, y: 1)
        static let spinCurve = UnitCurve.bezier(
            startControlPoint: spinStartControl,
            endControlPoint: UnitPoint(x: 0.68, y: 1)
        )
        /// 곡선의 시작 기울기(≈3). 지속을 `기울기 × 남은 각 / 놓는 속도` 로 잡아야 손을 뗀
        /// 순간의 각속도가 끊기지 않고 이어진다.
        static let spinStartSlope = Double(spinStartControl.y / spinStartControl.x)
        /// 느린 놓기가 순간이동처럼 보이지 않게 · 빠른 플릭이 늘어지지 않게 자른다.
        static let spinDurationRange: ClosedRange<TimeInterval> = 0.35...1.4

        /// 「동작 줄이기」에서 한 번 뒤집는 문턱 — 끈 거리(pt) 또는 튕긴 속도(pt/s).
        /// 끄는 동안 따라 도는 과정이 없어서, 문턱 없이는 살짝 스친 손에도 면이 통째로 바뀐다.
        static let reducedMotionFlipDistance: CGFloat = 40
        static let reducedMotionFlipVelocity: CGFloat = 300
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
        _angle = State(initialValue: isFlipped ? CardFlipGeometry.halfTurn : 0)
    }

    // MARK: - Body

    /// 액션이 하나도 없으면 버튼 행을 그리지 않는다 — 받은 명함 상세(#1227)에는
    /// 「명함 교환」·「QR 코드」가 할 일이 없다. 눌러도 아무 일 없는 버튼을 두느니 뺀다.
    private var hasActions: Bool {
        onExchange != nil || onQR != nil
    }

    public var body: some View {
        CardFlip(angle: angle, content: cardBody(showsBack:))
            // 히트 영역을 회전 전 레이아웃 프레임으로 고정한다. 회전된 내용으로 판정하면
            // 모서리만 보이는 순간 잡을 곳이 폭 0 으로 사라진다.
            .contentShape(Rectangle())
            .gesture(
                CardPanGesture(
                    isEnabled: onFlip != nil,
                    onBegan: beginDrag,
                    onChanged: updateDrag(translation:),
                    onEnded: endDrag(translation:velocity:)
                )
            )
            // 컨테이너가 접근성 요소가 아니라 자식 요소마다 붙는다 — 앞면 라벨·QR·링크 행
            // 어디에 포커스가 있어도 로터에 뜬다.
            .accessibilityActions {
                if let onFlip {
                    Button(
                        isFlipped ? Constants.flipToFront : Constants.flipToBack,
                        action: onFlip
                    )
                }
            }
            // 바깥(VoiceOver 액션 등)에서 면이 바뀐 경우만 돈다. 제스처가 요청한 토글이면
            // 각이 이미 그 면에 서 있어 아무 일도 하지 않는다.
            .onChange(of: isFlipped) { _, isFlipped in
                guard CardFlipGeometry(angle: angle).showsBack != isFlipped else { return }
                spin = nil
                withAnimation(reduceMotion ? nil : .easeInOut(duration: Metrics.flipDuration)) {
                    angle = CardFlipGeometry.restingAngle(near: angle) + CardFlipGeometry.halfTurn
                }
            }
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
        HStack(spacing: Metrics.linkSpacing) {
            Image.umcWordmark
                .resizable()
                .scaledToFit()
                .frame(width: Metrics.logoWidth, height: Metrics.logoHeight)
                // 옆의 타이틀 텍스트가 같은 뜻을 말한다 — 중복 낭독 방지.
                .accessibilityHidden(true)

            licenseText(Constants.title)
        }
    }

    /// 레퍼런스에 있던 두 요소는 의도적으로 빼 뒀다. 되살리기 전에 근거부터 확인할 것:
    /// **QR 은 뒷면에 그대로 둔다** — 양면에 QR 을 두면 같은 값이 두 번 나올 뿐이다.
    /// **호(arc) 게이지도 그리지 않는다** — 대응하는 진척률이 도메인에 없어서 그리는 순간
    /// 없는 수치를 지어내게 된다.
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

    // MARK: - Function

    /// 관성 스핀 중에 잡으면 지금 보이는 각에서 멈춘다. 애니메이션 없이 대입해야 진행 중인
    /// 스핀이 끊기고 그 각으로 점프한다.
    private func beginDrag() {
        if let spin {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { angle = spin.angle(at: .now) }
            self.spin = nil
        }
        dragStartAngle = angle
    }

    private func updateDrag(translation: CGFloat) {
        guard !reduceMotion else { return }
        angle = dragStartAngle + Double(translation) * Metrics.dragDegreesPerPoint
    }

    /// 면은 **놓는 순간** 확정한다. 스핀이 끝나기를 기다리지 않는 건 도중에 다시 잡힐 수
    /// 있어서다 — 그러면 다음 놓기가 다시 확정한다.
    private func endDrag(translation: CGFloat, velocity: CGFloat) {
        guard !reduceMotion else {
            flipOnce(translation: translation, velocity: velocity)
            return
        }

        let angularVelocity = Double(velocity) * Metrics.dragDegreesPerPoint
        let current = angle
        let target = CardFlipGeometry.restingAngle(
            near: current + angularVelocity * Metrics.momentumProjection
        )

        if target != current {
            let duration = spinDuration(delta: target - current, angularVelocity: angularVelocity)
            withAnimation(.timingCurve(Metrics.spinCurve, duration: duration)) {
                angle = target
            }
            spin = Spin(from: current, to: target, start: .now, duration: duration)
        }
        requestFace(restingAt: target)
    }

    /// 놓는 순간의 각속도를 곡선 시작 기울기로 이어 받는 지속. 속도가 없거나 되돌아가는
    /// 방향이면 이을 속도가 없으니 가장 짧게 둔다.
    private func spinDuration(delta: Double, angularVelocity: Double) -> TimeInterval {
        let range = Metrics.spinDurationRange
        guard angularVelocity * delta > 0 else { return range.lowerBound }

        let matched = Metrics.spinStartSlope * abs(delta) / abs(angularVelocity)
        return min(max(matched, range.lowerBound), range.upperBound)
    }

    /// 「동작 줄이기」 — 끈 방향으로 반 바퀴만, 애니메이션 없이 넘긴다.
    private func flipOnce(translation: CGFloat, velocity: CGFloat) {
        guard abs(translation) >= Metrics.reducedMotionFlipDistance
            || abs(velocity) >= Metrics.reducedMotionFlipVelocity else { return }

        let direction: Double = (translation != 0 ? translation : velocity) < 0 ? -1 : 1
        let target = CardFlipGeometry.restingAngle(near: angle)
            + direction * CardFlipGeometry.halfTurn
        angle = target
        requestFace(restingAt: target)
    }

    private func requestFace(restingAt target: Double) {
        guard CardFlipGeometry(angle: target).showsBack != isFlipped else { return }
        onFlip?()
    }

    // MARK: - Flip

    /// 카드를 Y축으로 돌리며 면 경계에서 면을 갈아 끼우는 컨테이너 (#1348).
    ///
    /// `Animatable` 이라 ``angle`` 에 **프레임마다 보간된 값**이 들어온다. 바깥의 `@State`
    /// 는 `withAnimation` 안에서도 도착 각만 들고 있어, 그 값으로 면을 고르면 회전 시작과
    /// 동시에 면이 바뀌어 버린다. 90° 판정을 하려면 중간 각도를 봐야 한다.
    ///
    /// 두 면을 겹쳐 그리지 않는다. `ZStack` + `opacity` 로 가르면 교차 구간에서 두 면이
    /// 한 프레임이라도 섞이는데, 여기서는 그릴 면 자체가 하나뿐이다. 안 보이는 면은
    /// `.hidden()` 으로 레이아웃 자리만 잡는다(#1363).
    ///
    /// 각은 누적이다(#1390) — 여러 바퀴 돌면 360° 를 넘고 왼쪽으로 돌리면 음수가 된다.
    /// 면 판정·거울상·그림자는 ``CardFlipGeometry`` 가 한 바퀴 안의 규칙으로 되돌린다.
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
                // 뒷면을 미리 반 바퀴 돌려 둔다. 바깥 회전과 합쳐 360° 의 배수가 되므로
                // 회전이 끝난 뒷면의 텍스트·QR 이 거울상이 아니라 정방향으로 읽힌다.
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

    /// 놓은 뒤 도는 관성 스핀 한 번. 애니메이션과 **같은 곡선**으로 역산하므로 도중에 잡은
    /// 각이 화면에 보이던 각과 맞는다.
    private struct Spin {
        let from: Double
        let to: Double
        let start: Date
        let duration: TimeInterval

        func angle(at date: Date) -> Double {
            let progress = min(1, date.timeIntervalSince(start) / duration)
            return from + (to - from) * Metrics.spinCurve.value(at: progress)
        }
    }

    /// 가로로 끄는 팬. SwiftUI `DragGesture` 는 `ScrollView` 안에서 `.gesture` 면 세로
    /// 스크롤을 막고 `.simultaneousGesture` 면 카드와 스크롤이 같이 움직인다. UIKit 팬은
    /// **시작 여부를 첫 이동 방향으로 고를 수 있어** 세로 끌기를 스크롤에 넘길 수 있다.
    ///
    /// 탭은 막지 않는다 — 팬은 이동이 있어야 시작하므로 카드 안 버튼 탭은 그대로 간다.
    private struct CardPanGesture: UIGestureRecognizerRepresentable {

        // MARK: - Property

        let isEnabled: Bool
        let onBegan: () -> Void
        let onChanged: (_ translation: CGFloat) -> Void
        let onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

        // MARK: - Function

        func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
            Coordinator()
        }

        func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
            let recognizer = UIPanGestureRecognizer()
            recognizer.delegate = context.coordinator
            return recognizer
        }

        func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
            recognizer.isEnabled = isEnabled
        }

        func handleUIGestureRecognizerAction(
            _ recognizer: UIPanGestureRecognizer,
            context: Context
        ) {
            let view = recognizer.view
            switch recognizer.state {
            case .began:
                // 시작 판정까지 움직인 거리를 버린다. 남겨 두면 잡는 순간 카드가 그만큼 튄다.
                recognizer.setTranslation(.zero, in: view)
                onBegan()
            case .changed:
                onChanged(recognizer.translation(in: view).x)
            case .ended:
                onEnded(recognizer.translation(in: view).x, recognizer.velocity(in: view).x)
            case .cancelled, .failed:
                // 끝나지 않은 채 끊겨도 가까운 면에 세운다 — 중간 각도로 멈춰 두지 않는다.
                onEnded(recognizer.translation(in: view).x, 0)
            default:
                break
            }
        }

        final class Coordinator: NSObject, UIGestureRecognizerDelegate {

            /// 가로가 우세할 때만 시작한다. 세로 끌기는 여기서 실패해 바깥 스크롤이 가져간다.
            func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
                guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
                let velocity = pan.velocity(in: pan.view)
                return abs(velocity.x) > abs(velocity.y)
            }
        }
    }
}

/// 플립 한 프레임의 기하 (#1348). 각도 하나에서 「어느 면을 그리는지 · 거울상을 되돌릴
/// 각 · 그림자가 얼마나 정면인지」가 전부 파생된다.
///
/// 뷰에서 떼어 둔 이유는 `CardInteractionPolicy` 와 같다 — 순수 값이라 뷰를 띄우지 않고
/// 테스트된다. 면 교체와 거울상 방지는 조용히 틀려도 빌드가 통과하는 종류의 규칙이다.
///
/// 각은 누적이다(#1390). 360° 를 넘거나 음수여도 한 바퀴로 정규화해 같은 규칙을 쓴다.
struct CardFlipGeometry {

    // MARK: - Property

    /// 반 바퀴. 앞면과 뒷면이 한 바퀴를 절반씩 나눠 갖는다.
    static let halfTurn: Double = 180

    let angle: Double

    /// 한 바퀴로 정규화한 각이 `[90, 270)` 이면 뒷면이다. 두 경계 모두 카드 폭이
    /// 0(`cos = 0`)이라 교체가 어느 프레임에도 보이지 않는다.
    var showsBack: Bool { (Self.halfTurn / 2..<Self.halfTurn * 1.5).contains(normalized) }

    /// 뒷면을 미리 되돌려 두는 각. 바깥 회전과 더해 360° 의 배수가 되면 정방향이다.
    var counterTurn: Double { showsBack ? Self.halfTurn : 0 }

    /// 정면도. 1 이면 카드가 정면, 0 이면 모서리만 보인다.
    var facing: Double { abs(cos(radians)) }

    /// 그림자가 좌우로 쓸리는 정도(0…1). 세로축 회전이라 가로로만 쓸린다.
    ///
    /// 얇은 판은 반 바퀴 돌면 윤곽이 같으니 그림자도 반 바퀴 주기로 둔다. `sin` 부호를
    /// 살리면 여러 바퀴 도는 동안 반 바퀴마다 그림자가 좌우를 오간다.
    var sway: Double { abs(sin(radians)) }

    private var radians: Double { angle * .pi / Self.halfTurn }

    private var normalized: Double {
        let remainder = angle.truncatingRemainder(dividingBy: Self.halfTurn * 2)
        return remainder < 0 ? remainder + Self.halfTurn * 2 : remainder
    }

    // MARK: - Function

    /// 가장 가까운 정지 각(반 바퀴의 배수).
    ///
    /// 정확히 가운데(90° · -90° …)는 **위쪽 배수**로 보낸다. ``showsBack`` 의 경계가
    /// `[90, 270)` 이라 이렇게 해야 정지 각의 면이 원래 각의 면과 늘 같다 — 기본
    /// `rounded()` 는 -90° 를 -180°(뒷면)로 보내는데 -90° 는 앞면이다.
    static func restingAngle(near angle: Double) -> Double {
        (angle / halfTurn + 0.5).rounded(.down) * halfTurn
    }
}

#if DEBUG
#Preview("앞면") {
    BusinessCardFaceView(card: BusinessCardPreviewData.myCard)
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
        .background(Color.grey100)
}

/// 드래그 회전(#1390) 확인용 — 카드를 가로로 끌거나 튕겨 본다. 「동작 줄이기」를 켜 두면
/// 같은 프리뷰가 회전 없이 한 번만 뒤집힌다.
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
