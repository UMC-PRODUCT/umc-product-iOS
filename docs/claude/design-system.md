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

## 콘텐츠 표면과 Liquid Glass

콘텐츠는 불투명한 의미색 표면에 표시하고, Liquid Glass는 콘텐츠 위의 탐색·조작에 사용한다.
카드가 탭 가능하다는 이유만으로 Glass를 적용하지 않는다. 브랜드 teal, Pretendard, 간격과 반경은 유지한다.

| 토큰 | 시스템 색상 | 용도 |
|------|-------------|------|
| `Color.Surface.canvas` | `systemGroupedBackground` | 화면 바탕 |
| `Color.Surface.content` | `secondarySystemGroupedBackground` | 카드·폼·요약·상태 콘텐츠 |
| `Color.Surface.inset` | `tertiarySystemGroupedBackground` | 카드 내부 보조 영역 |

`Surface`는 `CoreDesignSystem/Sources/Colors/Color+Tokens.swift`에 정의한다.
앱의 기존 라이트 모드 정책은 그대로 유지하며, 의미색 도입이 다크 모드 지원 확대를 뜻하지 않는다.

| 역할 | 적용 |
|------|------|
| 탭 바·툴바·시트 외곽 | 시스템 기본 효과 유지, 별도 Glass 중첩 금지 |
| 지도·콘텐츠 위 부유 조작 | `.regular` 또는 `.regular.interactive()` |
| 사진 위 독립 조작 | 대비가 확보된 경우 `.clear.interactive()` |
| Primary / Secondary CTA | `MainButton`의 `.glassProminent` / `.glass` |
| 목록·정보 배지·콘텐츠 필터·입력 필드 | 불투명 표면·기존 브랜드 색상, Glass 없음 |
| 메시지 작성 영역 | 답장·수정을 포함한 외곽 Glass 하나, 내부 전송 버튼은 불투명 강조색 |

`InfoBadge`와 `AttendanceStatusBadge`는 정보를 표시하는 불투명 배지다.
`ChipButton`은 콘텐츠 필터·선택·읽기 전용 태그이며, 부유 조작에는 시스템 버튼 또는 `MainButton`을 사용한다.
카드 안의 AI 요약·통계·첨부 내용도 콘텐츠 표면을 사용한다.

여러 **독립적인 조작 Glass**가 인접할 때만 `GlassEffectContainer`를 사용한다.
콘텐츠 카드 전체를 감싸거나 이미 시스템 Glass가 있는 요소에 덧씌우지 않는다.
시스템 Glass의 투명도 줄이기·대비 대응을 유지하고, 사용자 정의 이동·확대 애니메이션은
`accessibilityReduceMotion`을 따른다. 텍스트 카드의 고정 높이 대신 최소 높이를 사용해 큰 글자를 수용한다.

> Liquid Glass API 사용법은 `docs/claude/apple-frameworks/SwiftUI-Implementing-Liquid-Glass-Design.md` 참고.

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

- 인접한 독립 조작의 Glass는 `GlassEffectContainer`로 그룹화한다. 수치로 성능 개선을 보장하지 않는다.
- `glassEffectID`는 모핑 애니메이션 필요 시만 사용 (CPU 부하)
- List·Table의 콘텐츠 행과 미디어 자체에는 Glass를 적용하지 않는다. 시스템 탐색·조작은 유지한다.

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


## 콘텐츠를 표시할 수 없는 상태

목록 전체나 독립된 섹션이 비었거나, 검색에 일치하는 결과가 없거나, 권한 또는 오류로 콘텐츠를 표시할 수 없으면 SwiftUI의 `ContentUnavailableView`를 사용한다. 제목은 사용자가 기다리던 콘텐츠를 기준으로 짓고, 설명이 필요할 때 확인된 원인이나 다음 행동을 안내한다. 검색 맥락에는 `ContentUnavailableView.search(text:)`도 사용할 수 있다.

- iOS의 재시도 화면은 `CoreUIComponents.RetryContentUnavailableView`를 재사용한다. 기존 재시도 콜백을 연결하고, 문의를 제공하는 화면에서는 원본 `AppError`와 문의 정책을 보존한다.
- 권한 요청, 작성, 뒤로 가기 등 기존 복구 액션은 유지한다. 일부 섹션만 비었거나 실패하면 해당 섹션만 대체한다. 페이지 추가 실패나 오프라인 캐시가 있으면 이미 표시된 목록을 유지한다.
- 로딩은 진행 표시기, 폼 검증은 필드 메시지, 선택 전 입력 안내는 플레이스홀더로 처리한다. 위젯·컴플리케이션의 짧은 값과 배너는 각 표면의 표시 규약을 따른다.
- watchOS의 전체 화면은 기본 `ContentUnavailableView`로 구성하고, 필요한 힌트와 동작은 설명·액션 영역에 둔다. 대기열 카드나 확인 전까지 유지되는 공지 배너는 콘텐츠 위에 계속 표시한다.

[Apple ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview)
