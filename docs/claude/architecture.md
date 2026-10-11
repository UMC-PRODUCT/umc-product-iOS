# Architecture + Observation + 에러 처리

> 아키텍처 계층, ViewModel/View 패턴, 에러 처리 시스템에 대한 상세 레퍼런스.
> 핵심 요약은 `CLAUDE.md` 참고.

- 작성자: 제옹(euijjang97)

## Architecture

**Feature-Based Modular + Clean Architecture + Observation**

### 데이터 흐름

```
View ←→ ViewModel(@Observable) → UseCase(Protocol) → Repository → DataSource
                                    ↑
                   DIContainer가 Protocol 구현체 주입
```

### Feature 폴더 구조 (UMCApp · Tuist)

각 Feature 는 `{Name}Domain` · `{Name}Data` · `{Name}Presentation` 세 `staticFramework` 타겟이다
(`featureProject` 헬퍼 — `docs/claude/build-and-modules.md`). 레이어별 `Sources/` 와 `Tests/` 가 나란히 있다.

```
UMCApp/Features/{Feature}/
├── Project.swift            # featureProject(name:…)
├── Domain/
│   ├── Sources/
│   │   ├── Models/          # Entity (public)
│   │   ├── Interfaces/      # Repository Protocol
│   │   ├── UseCases/        # UseCase Protocol + 구현체
│   │   ├── Enums/ Requests/ # 도메인 열거형, UseCase 입력 모델
│   └── Tests/
├── Data/
│   ├── Sources/
│   │   ├── Router/          # Moya TargetType (엔드포인트 메타데이터만)
│   │   ├── DTOs/            # Request(Query/Body) · Response DTO + Mapping
│   │   └── Repositories/    # Repository 구현체 (MoyaNetworkAdapter 사용)
│   └── Tests/
└── Presentation/
    ├── Sources/
    │   ├── Views/           # SwiftUI View
    │   ├── ViewModels/      # @Observable ViewModel
    │   ├── Components/      # Feature 전용 컴포넌트
    │   ├── Navigation/      # {Feature}Destination enum (탭 스택 목적지, 자기 모듈 소유)
    │   └── …                # Extensions, Tags 등
    └── Tests/
```

- Mock/Stub 은 해당 레이어 `Sources/Mock` 에 `#if DEBUG` 로 둔다 (핵심 규칙 #5).
- DI 등록은 App 타겟의 `UMCApp/UMCApp/Sources/DIContainer+{Feature}.swift` 확장에서 한다.

### 계층 원칙

- **Presentation → Domain**: View/ViewModel은 UseCase Protocol에만 의존
- **Domain → Data**: UseCase는 Repository Protocol 사용, 구현체 모름
- **Protocol 기반 주입**: DIContainer가 런타임에 구현체 결정

### SOLID 원칙

| 원칙 | 적용 |
|------|------|
| **S**ingle Responsibility | View(UI 렌더링), ViewModel(상태 관리), UseCase(비즈니스 로직), Repository(데이터 접근) 분리 |
| **O**pen/Closed | Protocol 기반 설계로 기존 코드 수정 없이 새 구현체 추가 가능 |
| **L**iskov Substitution | Protocol 구현체는 언제든 교체 가능 (Mock, Real, Stub) |
| **I**nterface Segregation | 큰 Protocol보다 작고 명확한 Protocol 여러 개로 분리 |
| **D**ependency Inversion | 상위 모듈(UseCase)이 하위 모듈(Repository) 구현체가 아닌 Protocol에 의존 |

```swift
// DIP 예시: UseCase는 Protocol에만 의존
protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User
}

final class FetchUserUseCase {
    private let repository: UserRepositoryProtocol  // 구현체가 아닌 Protocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
}
```

### DIContainer (`CoreDI`)

```swift
// 등록 — App 타겟 DIContainer+{Feature}.swift
container.register(UserRepositoryProtocol.self) { UserRepository() }
container.register(LoginUseCaseProtocol.self) {
    LoginUseCase(repository: container.resolve(UserRepositoryProtocol.self))
}

// 사용 — View 에서 Environment 로 읽는다
@Environment(\.di) private var container
let useCase = container.resolve(LoginUseCaseProtocol.self)
```

- `@Observable` 클래스. 앱 루트가 `.environment(\.di, container)` 로 주입하고 Feature 는 `import CoreDI` 후 `@Environment(\.di)` 로 읽는다.
  Environment 기본값은 **빈 컨테이너**라 주입 누락은 `resolve` 의 `fatalError("No Factory registered")` 로 드러난다.
- `resolve()` 호출 시 캐싱 (싱글톤처럼 동작). 내부 저장소는 `@ObservationIgnored` — resolve 가 뷰 무효화를 일으키지 않는다.
- `resolveIfRegistered()`: 미등록이면 `nil` (fatalError 대신). 등록돼 있으면 `resolve` 와 동일하게 생성·캐싱.
- `resetCache()` / `resetCache(for:)`: 로그아웃 시 전체 또는 타입별 초기화.
- 등록 파일은 Feature 별로 쪼개져 있다: `DIContainer+Auth/Home/Notice/Activity/Community/MyPage/Project/BusinessCard/Maintenance/Authorization/MemberProfile/Certificate/WatchConnectivity.swift`.

### 화면 전환 (AppFlow + CoreRouting)

| 계층 | 타입 | 위치 | 역할 |
|------|------|------|------|
| 앱 생명주기 | `AppFlowViewModel` / `AppFlowState` | `UMCApp/UMCApp/Sources/AppFlow/` | bootstrap → login/signUp → main 전역 상태머신. 하위 Feature 는 `AppFlow` 환경값(클로저 묶음)으로만 전환을 요청 — 구체 타입 의존 없음 |
| 탭 경로 | `PathStore` · `NavigationTab` | `Core/Routing/Sources/` | 탭별 독립 `NavigationPath` 를 한 곳에서 보관. App 셸이 소유해 `.environment` 로 주입하고 각 탭 `NavigationStack(path:)` 바인딩 소스로 쓴다. 탭을 가로지르는 이동(`selectedTab` + push)의 진입점 |
| Feature 목적지 | `{Feature}Destination` (`Activity`·`Project`·`MyPage`·`BusinessCard`) | `{Feature}Presentation/Sources/Navigation/` | Feature 가 **자기 목적지 타입을 자기 모듈에** 두고, 루트 화면이 `.navigationDestination(for:)` 을 자기 탭 스택에 등록. 목적지 화면을 `public` 으로 열 필요 없음 |
| 과도기 목적지 | `NavigationDestination` (Home/Notice) | `UMCApp/UMCApp/Sources/Navigation/` | 아직 App 에 남은 Home·Notice 목적지. Notice 화면은 콜백 클로저로 의도만 올리고 push 는 `RootTabView`/`NavigationRoutingView` 가 수행(#1027). Feature 로 옮기면 사라질 타입 |
| 딥링크 | `AppDeepLink`(`message`·`card`·`attendance`) · `DeepLinkStore` | `UMCApp/UMCApp/Sources/Navigation/` | `umc://thread|notice/…`·`https://umc.it.kr/t/…`·푸시 → 탭 선택 + 경로 push |

- `NavigationPath` 는 타입 소거라 **Core → Feature, Feature → App 역방향 의존 없이** 서로 다른 Feature 목적지를 한 스택에 섞을 수 있다. 모든 목적지를 모은 전역 enum 을 Core 에 두지 않는다.
- `PathStore`·`AppFlowViewModel`·`ErrorHandler`·`UserSessionManager` 는 핵심 규칙 #1 의 명시적 예외(앱 생명주기 전역 관리자)로 `@Observable` 전역 객체다. 액터 격리 정책을 바꾸려면 네 타입을 함께 다룬다.
- 탭 표시 정보(제목·SF Symbol)는 App 타겟 확장 `NavigationTab+Presentation.swift` 에 둔다 — `CoreRouting` 은 라우팅 정체성만 가진다.

## Observation 패턴

### ViewModel 규칙

```swift
@Observable
final class ChallengerAttendanceViewModel {
    private var container: DIContainer
    private var useCase: ChallengerAttendanceUseCaseProtocol

    // Loadable로 비동기 상태 관리
    private(set) var attendanceState: Loadable<Attendance> = .idle

    // Action 메서드
    @MainActor
    func attendanceBtnTapped(userId: UserID) async {
        attendanceState = .loading
        do {
            let result = try await useCase.requestGPSAttendance(...)
            attendanceState = .loaded(result)
        } catch let error as DomainError {
            attendanceState = .failed(.domain(error))  // 인라인 에러
        } catch {
            errorHandler.handle(error, context: ...)   // Alert 에러
        }
    }
}
```

**필수 규칙:**
- `@Observable` 매크로 사용 (**NOT** `@StateObject`, `@ObservedObject`, `@Published`)
- 예외: 앱 생명주기 연결 전역 상태 관리자 (`AppFlowViewModel`)

### View 규칙

```swift
struct ChallengerAttendanceView: View {
    @State private var viewModel: ChallengerAttendanceViewModel

    init(container: DIContainer, ...) {
        _viewModel = State(initialValue: ChallengerAttendanceViewModel(
            container: container,
            ...
        ))
    }

    var body: some View { ... }
}
```

- `@State private var viewModel` 패턴으로 소유권 명시
- Action 기반 단방향 데이터 흐름

## 에러 처리 시스템

에러 타입·`Loadable`·`ErrorHandler`·`AlertPrompt` 는 모두 `UMCFoundation`(`Core/Foundation/Sources/Error/`, `Alert/`)에 있다.
`AppError` 하위로 `NetworkError`·`AuthError`·`DomainError`·`RepositoryError`·`ValidationError`·`LocationError` 가 있고,
전송 계층 에러는 `CoreNetwork.NetworkClient.appError(from:)` 가 `UMCFoundation.NetworkError` 로 변환해 올린다.

### Loadable (로컬/인라인 에러)

```swift
enum Loadable<T: Equatable> {
    case idle       // 초기 상태
    case loading    // 로딩 중
    case loaded(T)  // 성공
    case failed(AppError)  // 실패 (인라인 표시)
}

// View에서 사용
switch viewModel.attendanceState {
case .idle: Color.clear.task { await viewModel.fetch() }
case .loading: ProgressView()
case .loaded(let data): ContentView(data: data)
case .failed(let error): ErrorView(error: error, retry: ...)
}
```

### ErrorHandler (전역 Alert 에러)

```swift
// 네트워크 오류, 세션 만료 등 → Alert
errorHandler.handle(error, context: ErrorContext(
    feature: "Activity",
    action: "attendanceBtnTapped",
    retryAction: { [weak self] in await self?.retry() }
))
```

**에러 처리 선택 기준:**
- **ErrorHandler**: 작업 흐름 중단, 즉각적 사용자 액션 필요 (세션 만료, 권한 요청, 네트워크 오류)
- **Loadable**: 화면 내 상태 표시 (리스트 로딩 실패, 도메인 에러, 검증 실패)

### AlertPrompt (확인/취소 다이얼로그)

```swift
// ViewModel
@Observable
final class SomeViewModel {
    var alertPrompt: AlertPrompt?

    func deleteButtonTapped() {
        alertPrompt = AlertPrompt(
            title: "삭제 확인",
            message: "정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            isPositiveBtnDestructive: true,
            positiveBtnAction: { [weak self] in
                self?.delete()
            },
            negativeBtnTitle: "취소"
        )
    }
}

// View
.alertPrompt(item: $viewModel.alertPrompt)
```

**AlertPrompt 사용 기준:**
- 파괴적 작업 전 확인 (삭제, 초기화 등)
- 사용자 선택이 필요한 분기점
