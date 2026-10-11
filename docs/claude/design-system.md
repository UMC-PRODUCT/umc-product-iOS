# 디자인 시스템 + 성능 최적화

> 디자인 토큰, Typography, Glass Effect, 공용 컴포넌트, 렌더링 최적화 상세 레퍼런스.
> 핵심 요약은 `CLAUDE.md` 참고. Apple 프레임워크 API 상세는 `docs/claude/apple-frameworks/` 참고.

모듈: `UMCApp/Core/DesignSystem`(`CoreDesignSystem` — 토큰·색상·Typography·ButtonStyle) +
`UMCApp/Core/UIComponents`(`CoreUIComponents` — 공용 컴포넌트·모디파이어·`RemoteImage`).
토큰 정의: `Core/DesignSystem/Sources/Layout/DefaultConstant.swift`, `DefaultSpacing.swift`,
`Sources/Tokens/TypographyTokens.swift`, `Sources/Colors/Color+Tokens.swift`.
watchOS 는 별도 `CoreWatchDesignSystem` 을 쓰며 이 문서의 규칙을 따르지 않는다(`docs/claude/watch-design-system.md`).

- 작성자: 제옹(euijjang97)

## 레이아웃 상수 (`DefaultConstant`)

| 상수 | 값 | 용도 |
|------|----|------|
| `defaultSafeHorizon` | 16 | 좌우 기본 여백 |
| `defaultSafeTop` | 20 | 상단 기본 여백 |
| `defaultSafeBottom` | 56 | 하단 탭바 safe area |
| `defaultCornerRadius` | 30 | 기본 모서리 반경 |
| `cornerRadius` | 24 | 카드·아이콘 컨테이너 모서리 |
| `concentricRadius` | 40 | ConcentricRectangle 최소 반경 (`Edge.Corner.Style`) |
| `defaultCapsuleSpacing` | 28 | 캡슐형 요소 여백 |
| `iconSize` / `iconPadding` | 36 / 8 | 아이콘 컨테이너 |
| `minimumTouchTarget` | 44 | 최소 터치 영역 |
| `defaultListPadding` / `defaultCardPadding` | 16 / 24·16 | 리스트·카드 `EdgeInsets` |

## Typography (`AppFont`)

Pretendard 기반. `.appFont()` modifier로 줄간격 포함, `.font(.app())` 으로 줄간격 제외.
weight 는 `AppFontWeight`(`.regular` 기본, `Font.app(size:weight:)` 는 `.medium` 기본).

| Scale | Size | 용도 |
|-------|------|------|
| `.largeTitle` | 34pt | 최상위 제목 |
| `.title1` | 28pt | 주요 제목 |
| `.title2` | 22pt | 섹션 제목 |
| `.title3` | 20pt | 서브 섹션 |
| `.body` | 17pt | 본문 |
| `.callout` | 16pt | 카드 제목 |
| `.subheadline` | 15pt | 부제목 |
| `.footnote` | 13pt | 부가정보 |
| `.caption1` | 12pt | 보조 레이블 |
| `.caption2` | 11pt | 최소 텍스트 |

강조는 `appFont(_:weight:color:)` 의 weight 인자(`AppFontWeight`: `.regular`·`.medium`·`.semibold`, Pretendard 3종)로 준다.
시스템 `Font.TextStyle` 매핑이 있어 Dynamic Type 을 따른다.

### Typography 계층 (용도별)

| 용도 | AppFont | Color |
|------|---------|-------|
| 제목 | `.callout` + `weight: .semibold` | 기본 |
| 부제목 | `.subheadline` | `.grey600` |
| 부가정보 | `.footnote` | `.grey500` |

## ButtonStyle (`CoreDesignSystem/Styles/ButtonStyles.swift`)

`.primary` · `.secondary` · `.destructive` · `TextButtonStyle` — CTA 는 `MainButton`(CoreUIComponents)을 우선 쓰고,
일반 버튼은 이 스타일을 `.buttonStyle(.primary)` 처럼 적용한다. Liquid Glass 버튼은 아래 "Glass Effect 선택".

## Shape 패턴 (권장)

```swift
// ConcentricRectangle 사용 (디바이스별 일관성)
.clipShape(
    ConcentricRectangle(
        corners: .concentric(minimum: DefaultConstant.concentricRadius),
        isUniform: true
    )
)
.containerShape(.rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
```

## Glass Effect 선택

| Variant | 용도 |
|---------|------|
| `.regular` | 일반 카드, 폼 |
| `.regular.interactive()` | 탭 가능 요소 |
| `.clear` | 미디어/색상 배경 위 |
| `.glassProminent` (ButtonStyle) | Primary 버튼 |
| `.glass` (ButtonStyle) | Secondary 버튼 |

> Liquid Glass API 전체 사용법은 `docs/claude/apple-frameworks/SwiftUI-Implementing-Liquid-Glass-Design.md` 참고.

## 공용 UI 컴포넌트 (`UMCApp/Core/UIComponents/Sources/`)

| 폴더 | 컴포넌트 | 설명 |
|------|---------|------|
| `ArticleTextField/` | `ArticleTextField` | 제목/본문 겸용 텍스트 입력 (`ArticleTextFieldType` `.title`, `.content`) |
| `Auth/` | `LoginActionStack` · `SocialLoginLabel` · `LoginMethod` | 소셜 로그인 버튼 묶음 (Auth·MyPage 재사용) |
| `Badge/` | `AttendanceStatusBadge` · `InfoBadge` | 출석 상태·정보 뱃지 |
| `ChipButton/` | `ChipButton` (+ Style/Size/Environment) | 칩 형태 버튼 |
| `ChromaticLens/` | `ChromaticLens` · `RefractiveCinematic` | 굴절 효과 (Apple Intelligence 안내 등) |
| `Icon/` | `CardIconImage` | 카드형 아이콘 래퍼 |
| `Layout/` | `FlowLayout` | 줄바꿈 플로우 레이아웃 |
| `Loading/` | `LoadingView` | 로딩 인디케이터 |
| `Logo/` | `AuthLogoBlock` | 인증 화면 로고 블록 |
| `MainButton/` | `MainButton` (+ Size/Environment/Modifiers) | 주요 CTA 버튼 |
| `PlaceSelectView/` | `PlaceSelectView` · `MapPlacePickerView` · `PlaceSelection` | 장소 선택 (지도 피커·POI 길게 누르기 팁) |
| `Progress/` | `Progress` (+ `ProgressSize`) | 진행률 표시 |
| `Schedule/` | `DatePickerRow` · `TimePickerRow` · `DateTimeRow` · `InPersonToggle` · `AttendancePolicyTimeSection` | 일정 등록 폼 행 |
| `Section/` | `SectionHeaderView` · `SectionRightImage` | 섹션 헤더 |
| `State/` | `RetryContentUnavailableView` | 빈 상태/에러 + 재시도 |
| `ToolBar/` | `ToolBarCollection` | 툴바 헬퍼 |
| `Utilities/` | `RemoteImage`(Kingfisher) · `CapsuleModifier` · `DefaultBackgroundModifier` · `KeyboardToolbarModifier` · `NavigationModifier`/`NavigationTitle` · `RainbowBorderModifier` · `ShadowReuse` | 공용 모디파이어 |
| `Extensions/` | `Image+*Assets` · `UMCPartType+Color` · `ManagementTeam+Color` · `ScheduleIconCategory+Visual` | 에셋·도메인 열거형의 시각 매핑 (배치 기준: 색/이미지 매핑은 UIComponents) |

> 명함 카드 UI(`BusinessCardFaceView`)는 공용 컴포넌트가 아니라 `BusinessCardPresentation` 소유다 — 다른 Feature 는 그 모듈을 링크해 재사용한다(`build-and-modules.md` "경계 정책 — BusinessCard").

```swift
// ArticleTextField 사용 예시
ArticleTextField(
    placeholder: .title,
    text: $text,
    focused: $focused,
    submitLabel: .return,
    onSubmit: { /* action */ }
)
```

## 성능 최적화

### Liquid Glass (iOS 26)

- `GlassEffectContainer`로 그룹화 필수 (오프스크린 렌더링 66% 감소)
- `glassEffectID`는 모핑 애니메이션 필요 시만 사용 (CPU 부하)
- 적용 불가: List, Table, 미디어 콘텐츠

### View 렌더링

- Container-Presenter 패턴: Container(상태/로직) + Presenter(UI + Equatable)
- 클로저는 Equatable 비교에서 제외

```swift
struct CardPresenter: View, Equatable {
    let id: UUID
    let name: String
    var onTap: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}
```

### List/ForEach

- List 우선 사용 (LazyVStack보다 뷰 재사용 효율적)
- ForEach 내 조건부 뷰 금지 (lazy loading 깨짐)
- List에서 `.id()` 모디파이어 사용 금지
