# Build & Run + Tuist 모듈 구조

> 빌드 명령, Tuist 모듈화 구조, 의존성 방향에 대한 상세 레퍼런스.
> 핵심 요약은 `CLAUDE.md` 참고.

- 작성자: 제옹(euijjang97)

## Build & Run

프로젝트는 `AppProduct/`(레거시 xcodeproj)와 `UMCApp/`(Tuist 기반) **두 축**으로 관리됩니다.
**모든 작업은 `UMCApp/`에서만** 합니다. `AppProduct/`는 `v2.2.0`에 동결돼 있고(핵심 규칙 #9), CI도
UMCApp만 돕니다 — `.github/workflows/tuist-ci.yml`(`develop` push/PR, `macos-26`, `UMCApp/Makefile` 사용).
App Store 현행 릴리즈는 3.5.0(태그 `v3.5.0`)이며 `UMCApp/`에서 빌드했다.

### AppProduct (xcodeproj) — 열람 전용

```bash
# 레거시 참고용으로만 연다. 빌드·수정하지 않는다.
open AppProduct/AppProduct.xcodeproj
```

### UMCApp (Tuist)

Tuist 버전은 `UMCApp/mise.toml` 로 팀 전원 고정됩니다. Makefile이 `mise exec --` 래퍼를 제공하므로 **로컬 tuist 버전 차이가 발생하지 않습니다**.

```bash
cd UMCApp

# 최초 1회 (신규 팀원)
brew install mise      # mise가 없다면
make bootstrap         # mise.toml 기반 tuist 설치
make install           # SPM 의존성

# 일상 작업
make generate          # .xcworkspace 생성
make open              # Xcode 열기 (없으면 자동 generate)
make build             # Debug 빌드 (SCHEME=… 으로 모듈 단위)
make build-watch       # watchOS 앱(UMCWatchApp) 빌드
make test              # xcodebuild 테스트 (SCHEME=… 으로 모듈 단위)
make test-network      # CoreNetwork 단위+통합 테스트 (TEST_SERVER_URL 자동 전달)
make pick / test-pick  # 스킴을 골라 빌드/테스트 (대화형)
make graph             # 의존성 그래프(graph.png)
make doctor            # 환경 진단 (mise/tuist/xcode 버전)
make reset             # 꼬였을 때 전체 초기화
make help              # 전체 타겟 목록
```

자세한 사용법은 `UMCApp/MAKEFILE_GUIDE.md` 참고.

#### 로컬 테스트 서버 (`AppProductTestServer/`)

레포 루트의 `AppProductTestServer/`는 CoreNetwork 통합 테스트용 **Vapor 서버**다(DB 없음).
`UMCApp/Core/Network/Tests/Integration/AppProductTestServerIntegrationTests.swift`가 `TEST_SERVER_URL`
(기본 `http://127.0.0.1:8080`)에 1.5초 ping 으로 서버를 감지해 떠 있을 때만 실행된다.

```bash
cd AppProductTestServer && make integration   # start → UMCApp make test-network → stop 원샷
cd AppProductTestServer && make start/stop    # 수동으로 띄워두고 반복 실행할 때
```

#### 빌드 번호 (`CURRENT_PROJECT_VERSION`)

`Makefile`이 배포 브랜치명(`release/{version}/{build}` · `testflight/external/{version}/{build}`)의 끝 숫자를
`TUIST_BUILD_NUMBER`로 넣어 `make generate` 시 `CURRENT_PROJECT_VERSION`에 반영한다. 105 미만이면 `make`가
거부한다(`MIN_BUILD_NUMBER`). 로컬 기본값은 `1`. 직접 지정은 `TUIST_BUILD_NUMBER=42 make generate`.
Xcode Cloud에서는 `CI_BRANCH`로 브랜치명을 받는다. 배포 절차 전체는 `.agents/skills/deploy-ios/SKILL.md`.

## Tuist 모듈 구조 (UMCApp)

`UMCApp/` 폴더는 Tuist 기반의 별도 모듈화 프로젝트입니다. `AppProduct/`와 병행하여 관리됩니다.

### 버전 관리 & 빌드 래퍼

| 파일 | 역할 |
|------|------|
| `mise.toml` | Tuist 버전 고정 (현재 `4.208.0`) — 팀 전원 동일 버전 보장 |
| `Makefile` | `mise exec -- tuist …` 래퍼. 모든 Tuist/xcodebuild 명령의 **표준 진입점** |
| `MAKEFILE_GUIDE.md` | 팀원용 사용 가이드 |

> Tuist 버전을 올릴 때는 **`mise.toml` 만** 수정하고 PR 본문에 릴리스 노트를 첨부합니다.
> Makefile / 로컬 tuist 설치는 손대지 않습니다.

### 전체 구조

```
UMCApp/
├── Makefile                       # 빌드/생성 래퍼 (mise exec 기반)
├── MAKEFILE_GUIDE.md              # 팀원용 사용 가이드
├── mise.toml                      # tuist 버전 고정
├── Project.swift                  # 앱 타겟 정의
├── Workspace.swift                # 전체 워크스페이스 (Core/*, Features/* glob + Widget/Watch)
├── Tuist.swift                    # Tuist 시스템 설정
├── Tuist/
│   ├── Package.swift              # SPM 외부 의존성 (Aquila, Moya, Kingfisher, KakaoSDK, GoogleSignIn, Firebase)
│   └── ProjectDescriptionHelpers/
│       ├── Project+Core.swift            # Core 모듈 공통 헬퍼 (coreProject)
│       ├── Project+Feature.swift         # Feature 모듈 공통 헬퍼 (featureProject · 3타겟)
│       ├── Project+WatchApp.swift        # watchOS 앱 헬퍼 (watchAppProject)
│       ├── Project+WidgetExtension.swift # 위젯/Complication 익스텐션 헬퍼
│       └── Settings+Recommended.swift    # 전역 빌드 설정 · MARKETING_VERSION · 빌드 번호 · 서명 팀
├── Secrets/                       # Shared.xcconfig (BASE_URL 등, 팀 내부 수령)
├── Scripts/                       # verify-secrets.sh · 워크북 계약 검사 스크립트
├── ci_scripts/                    # Xcode Cloud ci_post_clone.sh
├── Core/                          # 12개 공유 인프라 모듈
│   ├── Foundation/                # UMCFoundation — Loadable/ErrorHandler/AppError, Config, 디코딩 헬퍼, LocationManager (iOS+watchOS)
│   ├── Domain/                    # CoreDomain — 공용 도메인 모델·UserSessionManager (iOS+watchOS)
│   ├── Network/                   # CoreNetwork — Aquila 전송 계층 + Moya Router, 소셜 로그인, KeychainTokenStore, STOMP
│   ├── DI/                        # CoreDI — DIContainer · `\.di` Environment 키
│   ├── Routing/                   # CoreRouting — PathStore(탭별 NavigationPath) · NavigationTab
│   ├── DesignSystem/              # 디자인 토큰, 색상, Typography, ButtonStyle
│   ├── UIComponents/              # 공용 UI 컴포넌트 (Kingfisher)
│   ├── Photo/                     # 사진 선택·처리 공통 기능
│   ├── NearbyExchange/            # 근거리 명함 교환 인프라
│   ├── WatchConnectivity/         # iOS ↔ watchOS 통신
│   ├── WatchDesignSystem/         # watchOS 전용 디자인 시스템
│   └── WidgetShared/              # Widget-App 공유 모델
├── Features/                      # 10개 기능 모듈
│   ├── Activity/
│   ├── Auth/
│   ├── Badge/
│   ├── BusinessCard/              # 전자명함 (2D 카드 UI · QR · 근거리 교환)
│   ├── Community/
│   ├── Home/
│   ├── Maintenance/                # 점검 상태 및 원격 운영 안내
│   ├── MyPage/
│   ├── Notice/
│   └── Project/                    # 프로젝트 목록·운영진 관리·지원·지원자 심사
├── UMCAppWidget/                  # Widget Extension 타겟
├── UMCWatchApp/                   # watchOS Companion App 타겟
└── UMCWatchComplication/          # watchOS Complication 타겟
```

### 모듈 의존성 방향

```
App Target (UMCApp)
    ↓
Feature Presentation  (Domain + CoreDesignSystem + CoreUIComponents)
    ↓
Feature Domain        (UMCFoundation)
Feature Data          (Domain + CoreNetwork + UMCFoundation)
    ↓
Core Modules          (Foundation / Network / DesignSystem / UIComponents / DI)
    ↓
External Packages     (Aquila / Moya / Kingfisher / KakaoSDK / GoogleSignIn / Firebase)
```

> **Aquila 경계**: `import Aquila` / `import AquilaMoya` 는 **`CoreNetwork` 소스·테스트에서만** 한다.
> Feature Data·App 타겟은 CoreNetwork 가 감싼 `NetworkClient`·`MoyaNetworkAdapter`·`StompConnection`
> (typealias)만 쓴다. 상세는 `docs/claude/network-router.md` "전송 계층(Aquila)".

> **경계 정책 — BusinessCard**: MyPage·Home·Community·Activity·Auth 등 명함을 노출하는 Feature는 `BusinessCardPresentation`만 링크해 카드 UI(`BusinessCardFaceView` 등)를 재사용하며, 카드 화면을 자체 구현하지 않는다. 2D SwiftUI(`BusinessCardFaceView`)는 여전히 정본 카드 UI이고, 이 경계 자체는 렌더링 방식과 무관하게 유효하다.
>
> 렌더링 이력: 초기 구상이던 RealityKit(3D)은 #1196에서 ARKit·RealityKit 링크를 풀며 한 차례 폐기됐다. #1245 Phase 0 스파이크의 "조건부 Go" 판정으로 다시 살아났다. #1246~#1249를 거치며 USDZ 템플릿·온디바이스 합성기·그리드 스냅샷 파이프라인까지 올라갔다. 그러나 #1347(라이선스 카드 톤 재설계)·#1348(`rotation3DEffect` 플립)에서 방향을 다시 잡았고 **#1349 에서 스택을 통째로 철거했다.** 그래서 지금 `UMCApp` 에 `import RealityKit` 은 0건이고 2D SwiftUI 가 다시 유일한 렌더링 경로다. 당시 실측치와 앵커 규약, 캐시 설계 근거는 `docs/claude/archive/` 에 남겨 뒀다.

> **경계 정책 — 일정(Schedule) (#981 확정 · #1212 갱신)**: 전용 Schedule Feature 모듈은 **신설하지 않는다.**
> 일정 도메인의 단일 소유자는 `HomeDomain`(모델·Repository/UseCase Protocol) + `HomeData`(`ScheduleV2Router`·`ScheduleRepository`·일정 DTO) + `HomePresentation`(일정 화면)이다.
> Activity 등 다른 Feature 는 `ScheduleDetailData`·`ScheduleLocation`·`ScheduleAttendancePolicy`·`ScheduleRepositoryProtocol` 을 **HomeDomain 에서 재사용**하며 자체 일정 모델을 다시 만들지 않는다.
> 단, 엔드포인트별 wire DTO 는 각 Feature Data 에 두는 것이 원칙이다 — 출석 응답의 `ScheduleLocationDTO`/`ScheduleAttendancePolicyDTO`(ActivityData)와 V2 일정 응답의 동명 DTO(HomeData)는 서로 다른 엔드포인트 계약이므로 의도적으로 분리돼 있고, 둘 다 같은 HomeDomain 모델로 매핑한다. (ActivityData → HomeData 링크는 HomeData 의 CoreML 리소스 번들까지 끌고 오므로 통합하지 않는다.)
>
> **플랫폼 축 (#1212 확정)**: Watch 앱이 ActivityDomain 출석 UseCase 를 쓰기 위해 일정 모델을 옮기지 않는다 — 소유자는 그대로 두고 `HomeDomain`(+의존 사슬의 `NoticeDomain`)과 `CoreDomain` 의 **Domain 타겟만** iOS+watchOS 멀티플랫폼으로 개방한다. 세 타겟의 소스 import 는 `Foundation`·`UMCFoundation`·`NoticeDomain`·`SwiftData` 뿐이라 watchOS 제약이 없고, 모델을 옮기지 않으므로 iOS 측 `import HomeDomain` 은 전부 무변경이다. 워치가 재사용하는 타입은 `ScheduleDetailData`·`ScheduleLocation`·`ScheduleAttendancePolicy`·`ScheduleAttendanceStatus`·`ScheduleRepositoryProtocol`(HomeDomain)과 `ChallengerInfo`(CoreDomain). `Data`/`Presentation` 타겟은 iOS 전용 그대로다 — `ActivityData` 는 Moya/CoreNetwork 의존이라 워치가 링크할 수 없고, 워치의 데이터 수급은 WatchConnectivity 경로(#1210)로 해결한다. (대안이던 "일정 모델 CoreDomain 승격"은 단일 소유자 경계를 깨면서 기존 import 도 대량으로 깨뜨리므로 기각.)

### Feature 모듈 구조

각 Feature는 Clean Architecture에 따라 **3개 타겟**으로 분리됩니다.

| 타겟 | Product Type | Bundle ID 패턴 | Sources |
|------|-------------|----------------|---------|
| `{Name}Domain` | `.staticFramework` | `dev.umc.feature.{name}.domain` | `Domain/Sources/**` |
| `{Name}Data` | `.staticFramework` | `dev.umc.feature.{name}.data` | `Data/Sources/**` |
| `{Name}Presentation` | `.staticFramework` | `dev.umc.feature.{name}.presentation` | `Presentation/Sources/**` |

### 플랫폼(destination) 정책

기본값은 iOS 전용이다. watchOS 재사용이 필요한 타겟만 `[.iPhone, .appleWatch]` / `.multiplatform(iOS: "26.4", watchOS: "26.4")` 로 개방한다 — Core 모듈은 `coreProject` 의 `destinations`/`deploymentTargets` 인자, Feature Domain 은 `featureProject` 의 `domainDestinations`/`domainDeploymentTargets` 인자로 지정한다.

| watchOS 개방 타겟 | 매니페스트 |
|-------------------|-----------|
| `UMCFoundation` | `Core/Foundation/Project.swift` |
| `CoreWatchConnectivity` | `Core/WatchConnectivity/Project.swift` |
| `CoreWatchDesignSystem` | `Core/WatchDesignSystem/Project.swift` (watchOS 전용) |
| `CoreDomain` | `Core/Domain/Project.swift` |
| `NoticeDomain` | `Features/Notice/Project.swift` |
| `HomeDomain` | `Features/Home/Project.swift` |
| `ActivityDomain` | `Features/Activity/Project.swift` |

이 목록은 #1212 에서 확정됐다. 그 전에는 `ActivityDomain` 만 destination 이 watchOS 로 열려 있고 `HomeDomain`·`CoreDomain` 의존은 `condition: .when([.ios])` 로 iOS 한정이라, watchOS 로 빌드하면 `unable to resolve module dependency: 'HomeDomain'` 으로 실패했다(어떤 watch 타겟도 링크하지 않아 드러나지 않았을 뿐). #1212 에서 의존 사슬 전체를 개방하며 조건부 의존을 제거했고, `UMCWatchApp` 이 `ActivityDomain`·`HomeDomain` 을 링크한다.

### ProjectDescriptionHelpers

보일러플레이트 제거를 위해 두 개의 헬퍼 함수를 사용합니다.

```swift
// Core 모듈 생성 (테스트 타겟은 includesTests: true 로 함께 생성)
coreProject(
    name: "CoreNetwork",
    bundleIdSuffix: "network",
    dependencies: [
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
        .external(name: "Aquila"), .external(name: "AquilaMoya"), .external(name: "Moya"),
    ],
    includesTests: true,
    testDependencies: [.external(name: "Aquila"), .external(name: "AquilaMoya")],
    testEntitlements: "Tests/CoreNetworkTests.entitlements"
)

// Feature 모듈 생성 (Domain/Data/Presentation 3개 타겟 자동 생성)
featureProject(
    name: "Auth",
    domainExtraDependencies: [],
    dataExtraDependencies: [],
    presentationExtraDependencies: [],
    includesDomainTests: true, includesDataTests: true, includesPresentationTests: true
)
```

`coreProject` 는 `destinations`/`deploymentTargets`/`resources`/`additionalSettings`/`includesTests`/
`testDependencies`/`testEntitlements` 를, `featureProject` 는 `domainDestinations`/`domainDeploymentTargets`
와 레이어별 `includes*Tests`/`*TestDependencies` 를 선택적으로 받는다. 워치 앱은 `watchAppProject`,
위젯·Complication 은 `widgetExtensionProject` 헬퍼를 쓴다.
두 헬퍼 모두 리소스 파라미터(`dataResources`/`presentationResources`)를 선택적으로 받는다.
`staticFramework`는 Compile Sources 산출물이 소비 타겟까지 전파되지 않으므로, 런타임에 필요한
자산은 별도 리소스 번들로 명시해야 한다 — 예: `HomeData`의 CoreML 모델(`dataResources`).

### 외부 의존성

`UMCApp/Tuist/Package.swift` 기준. 버전은 `from:` 하한이며 실제 해석값은 `Tuist/Package.resolved` 에 고정된다.

| 패키지 | 버전 지정 | 사용처 |
|--------|------|--------|
| [Aquila](https://github.com/JEONG-J/Aquila) (`Aquila` · `AquilaMoya`) | `revision` 고정 (`c167df60…`) | CoreNetwork — HTTP 전송·토큰 갱신·Keychain 저장소·STOMP·로깅 (#1562) |
| Moya | 15.0.3+ | CoreNetwork (Router `TargetType`), Aquila 의 `AquilaMoya` 가 재사용 |
| Kingfisher | 8.6.1+ (resolved 8.8.0) | CoreUIComponents (`RemoteImage`) |
| KakaoSDK (kakao-ios-sdk) | 2.27.0+ | CoreNetwork (`KakaoLoginManager`·`KakaoPlusManager`) |
| GoogleSignIn-iOS | 9.1.0+ | CoreNetwork (`GoogleLoginManager`) |
| firebase-ios-sdk (`FirebaseCore`·`FirebaseMessaging`) | 12.7.0+ | App 타겟 — FCM 푸시. 킬스위치·강제 업데이트는 GitHub Pages 원격 설정이라 RemoteConfig 는 쓰지 않는다(#1389) |

- Aquila 는 태그가 아닌 **커밋 revision 으로 고정**한다. 올릴 때는 `Package.swift` 의 `revision` 과
  `Package.resolved` 를 함께 갱신하고 `make test-network` 로 CoreNetwork 테스트를 돌린다.
- 외부 의존성은 전부 `.staticFramework`(`productTypes: [:]`)라 ObjC 카테고리 유실을 막기 위해
  전역 `OTHER_LDFLAGS` 에 `-ObjC` 가 들어 있다(`Settings+Recommended.swift`). `AppAuth`·`AppCheckCore`·
  `Firebase` 타겟은 빈 `.o` 의 `has no symbols` 경고를 `-no_warning_for_no_symbols` 로 끈다(#1394).

### 주요 설정

- **Tuist 버전**: `UMCApp/mise.toml` 고정 (`4.208.0`)
- **Deployment Target**: iOS 26.4 (`Project.swift` 기준). watchOS 개방 타겟은 watchOS 26.4 병기 ("플랫폼(destination) 정책" 참고)
- **앱 타겟**: `destinations: [.iPhone]`(iPad 제외 — 출시본과 동일), `bundleId: com.umc.product`(변경 금지),
  `UIUserInterfaceStyle: Light` 고정, 권한 문구는 `Project.swift` infoPlist 에 주석과 함께 관리
- **버전**: `MARKETING_VERSION` 은 `Settings+Recommended.swift`(현재 `3.5.0`), `CURRENT_PROJECT_VERSION` 은
  배포 브랜치명에서 유도("빌드 번호" 참고). `DEVELOPMENT_TEAM`(`8B8B4462NV`)·`CODE_SIGN_STYLE` 도 매니페스트 고정
- **Product Type**: 모든 모듈 `.staticFramework`
- **Bundle ID**: Core → `dev.umc.core.*` / Feature → `dev.umc.feature.*.*`
- **Workspace**: glob(`Core/*`, `Features/*`) + `UMCAppWidget`, `UMCWatchApp`, `UMCWatchComplication` 명시 포함
- **워치 앱 임베드**: 현재 앱 타겟은 `UMCWatchApp` 을 **임베드하지 않는다**(`Project.swift` 의 주석 처리된
  `.project(target: "UMCWatchApp")`). 워치 프로젝트·`make build-watch`·CI 빌드는 그대로 살아 있으며, 다음
  릴리즈에 담을 때 그 줄만 되살린다.
- **보호 경로**: `.github/CODEOWNERS` 가 `UMCApp/Tuist/`·`Project.swift`·`Makefile`·`Secrets/`·entitlements·
  `Core/{Foundation,DesignSystem,UIComponents,Domain,DI,Network}`·`AppProduct/` 를 소유자 승인 필수로 건다

### 공유 Keychain Access Group

iOS 앱과 watchOS 앱은 로그인 토큰용 공유 그룹 `$(AppIdentifierPrefix)com.umc.product.shared` 를
`keychain-access-groups` entitlement 의 **첫 항목**으로 선언합니다. 팀 ID(`8B8B4462NV`)를 문자열로
박지 않고 `$(AppIdentifierPrefix)` 를 쓰는 것이 레포 관례입니다
(`UMCApp/Core/Network/Tests/CoreNetworkTests.entitlements` 동일).

| 타겟 | entitlements 파일 | 배선 위치 |
|------|------------------|----------|
| iOS 앱 | `UMCApp/UMCApp.entitlements:26-30` | `UMCApp/Project.swift:106` |
| watchOS 앱 | `UMCApp/UMCWatchApp/UMCWatchApp.entitlements:7-11` | `UMCApp/UMCWatchApp/Project.swift:14` |

- **배열 순서가 계약이다.** `kSecAttrAccessGroup` 을 지정하지 않은 `SecItemAdd` 는 배열 **첫 항목**에
  저장한다. `UMCApp/Core/Network/Sources/Auth/KeychainTokenStore.swift` 는 #1562 이후
  `Aquila.KeychainTokenStore(service:account: "tokenPair")` 를 **access group 없이** 생성해 토큰 쌍을 저장하므로
  이 기본값 규칙에 전적으로 의존한다. 그래서 공유 그룹이 첫 번째다. (Aquila 쪽도 `accessGroup` 이 nil 이면
  쿼리에 그룹을 넣지 않는다.)
- **두 번째 항목(각 타겟 자기 App ID 그룹)은 안전장치다.** 검색·삭제는 access group 미지정 시 앱이 가진
  모든 그룹을 대상으로 하므로, 기존 배포판이 기본 그룹(`$(AppIdentifierPrefix)com.umc.product`)에 저장해 둔
  토큰이 계속 읽힌다. 이 줄을 빼면 업데이트 즉시 전 사용자 강제 로그아웃이다.
- **레거시 항목 이전(#1562).** Aquila 전환 전에는 `accessToken`·`refreshToken` 두 account 로 따로 저장했다.
  `KeychainTokenStore.readTokens()` 는 쌍 항목이 없으면 레거시 두 항목을 `kSecMatchLimitAll` + `kSecReturnAttributes`
  로 전 그룹에서 읽어 **같은 access group 끼리 짝지은 뒤** 쌍 항목으로 저장하고 레거시를 지운다. 저장·삭제
  순서는 actor 내부 대기열(`acquireOperation`)로 직렬화되므로, 이 흐름을 건드릴 때는
  `Tests/Auth/KeychainTokenStoreTests.swift` 와 `UMCApp/Tests/AquilaKeychainIntegrationTests.swift` 를 같이 본다.
- **워치는 배선까지 확인한다.** `watchAppProject(entitlements: .file(path: "UMCWatchApp.entitlements"))` 로
  인자를 넘겨야 실제로 적용된다. 파일만 만들고 인자를 안 넘기면 무효다 — #1147 유실이 정확히 이 형태였다.
- **watchOS 는 keychain 을 공유하지 않는다.** Apple Watch 는 자체 keychain 을 가진 별개 기기라 access
  group 을 맞춰도 워치가 iPhone 의 항목을 읽지 못한다. access group 은 동일 기기 내 동일 팀 서명 타겟
  (앱·확장) 간 공유 메커니즘이다. 워치 토큰은 WatchConnectivity 로 iPhone→Watch 전송 후 워치 자체
  keychain 에 저장하는 경로이며 #1210/#1211 범위다. 또한 Aquila 저장소의 기본 accessibility 가
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`(`synchronizable: false`)라 iCloud Keychain 동기화 대상도 아니다.
- **서명 주의**: 두 App ID(`com.umc.product` · `com.umc.product.watchkitapp`)에 Keychain Sharing
  capability 가 없으면 실기기/아카이브 서명 단계에서 실패하고, 런타임 증상은 `SecItemAdd` 의
  `errSecMissingEntitlement(-34018)` 다.

> **유실 이력**: PR #627(`744ad80b`)이 공유 그룹(`$(AppIdentifierPrefix)dev.umc.shared`)을 추가했으나,
> #1147(`a68f93c2`) 번들 ID 정렬 커밋이 "미사용 keychain-access-groups 제거" 사유로 iOS·watch 양쪽에서
> 걷어냈다(워치 entitlements 는 파일째 삭제). 이미 **두 번 유실된** entitlement 다 — "미사용"으로 보여도
> 제거하지 않는다.
