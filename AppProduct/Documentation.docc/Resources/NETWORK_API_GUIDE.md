# Network API 사용 가이드

UMC 프로젝트의 네트워크 레이어 사용 방법을 단계별로 설명합니다.

## 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [새로운 API 추가하기](#새로운-api-추가하기)
3. [완전한 예제: User API](#완전한-예제-user-api)
4. [에러 처리](#에러-처리)
5. [테스트 작성](#테스트-작성)

---

## 아키텍처 개요

### 데이터 흐름

```
View
  ↓ (Action)
ViewModel (@Observable)
  ↓ (UseCase Protocol 호출)
UseCase (비즈니스 로직)
  ↓ (Repository Protocol 호출)
Repository (데이터 접근)
  ↓ (MoyaNetworkAdapter)
NetworkClient (JWT 인증 + 토큰 갱신)
  ↓
Server
```

### 계층별 책임

| 계층 | 책임 | 의존성 |
|------|------|--------|
| **View** | UI 렌더링, 사용자 이벤트 처리 | ViewModel |
| **ViewModel** | 상태 관리, View 로직 | UseCase Protocol |
| **UseCase** | 비즈니스 로직, 도메인 규칙 | Repository Protocol |
| **Repository** | 데이터 소스 접근, DTO ↔ Entity 변환 | MoyaNetworkAdapter |
| **NetworkClient** | JWT 인증, 토큰 갱신, 네트워크 요청 | URLSession |

### 핵심 원칙

- **Protocol 기반 의존성**: 구현체가 아닌 Protocol에 의존
- **의존성 주입**: DIContainer가 런타임에 구현체 주입
- **단방향 데이터 흐름**: View → ViewModel → UseCase → Repository

---

## 새로운 API 추가하기

### Step 1: Moya TargetType 정의

**위치**: `Features/{Feature}/Data/DataSources/`

```swift
// Features/User/Data/DataSources/UserAPI.swift
import Foundation
import Moya

enum UserAPI {
    case getMe
    case updateProfile(name: String, bio: String)
    case deleteAccount
}

extension UserAPI: TargetType {
    var baseURL: URL {
        URL(string: "https://api.umc.com")!
    }

    var path: String {
        switch self {
        case .getMe:
            return "/users/me"
        case .updateProfile:
            return "/users/me"
        case .deleteAccount:
            return "/users/me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getMe:
            return .get
        case .updateProfile:
            return .put
        case .deleteAccount:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case .getMe:
            return .requestPlain

        case .updateProfile(let name, let bio):
            let parameters: [String: Any] = [
                "name": name,
                "bio": bio
            ]
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )

        case .deleteAccount:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
```

### Step 2: DTO (Data Transfer Object) 정의

**위치**: `Features/{Feature}/Data/DTOs/`

```swift
// Features/User/Data/DTOs/UserDTO.swift
import Foundation

/// 서버 응답 DTO
struct UserDTO: Codable {
    let id: Int
    let name: String
    let email: String
    let bio: String?
    let profileImageUrl: String?
    let createdAt: String
}

extension UserDTO {
    /// DTO → Domain Entity 변환
    func toDomain() -> User {
        User(
            id: UserID(value: id),
            name: name,
            email: email,
            bio: bio,
            profileImageUrl: profileImageUrl.flatMap { URL(string: $0) },
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}
```

### Step 3: Repository Protocol 정의

**위치**: `Features/{Feature}/Domain/Interfaces/`

```swift
// Features/User/Domain/Interfaces/UserRepositoryProtocol.swift
import Foundation

/// User 데이터 접근을 추상화하는 Repository Protocol
protocol UserRepositoryProtocol {
    /// 내 프로필 조회
    func getMe() async throws -> User

    /// 프로필 수정
    func updateProfile(name: String, bio: String) async throws -> User

    /// 회원 탈퇴
    func deleteAccount() async throws
}
```

### Step 4: Repository 구현

**위치**: `Features/{Feature}/Data/Repositories/`

```swift
// Features/User/Data/Repositories/UserRepository.swift
import Foundation

struct UserRepository: UserRepositoryProtocol {
    // MARK: - Property

    private let adapter: MoyaNetworkAdapter

    // MARK: - Initializer

    init(adapter: MoyaNetworkAdapter) {
        self.adapter = adapter
    }

    // MARK: - UserRepositoryProtocol

    func getMe() async throws -> User {
        // 1. API 호출
        let response = try await adapter.request(UserAPI.getMe)

        // 2. CommonDTO 파싱
        let commonDTO = try JSONDecoder().decode(
            CommonDTO<UserDTO>.self,
            from: response.data
        )

        // 3. 성공 여부 확인
        guard commonDTO.isSuccess, let userDTO = commonDTO.result else {
            throw RepositoryError.serverError(message: commonDTO.message)
        }

        // 4. DTO → Domain Entity 변환
        return userDTO.toDomain()
    }

    func updateProfile(name: String, bio: String) async throws -> User {
        let response = try await adapter.request(
            UserAPI.updateProfile(name: name, bio: bio)
        )

        let commonDTO = try JSONDecoder().decode(
            CommonDTO<UserDTO>.self,
            from: response.data
        )

        guard commonDTO.isSuccess, let userDTO = commonDTO.result else {
            throw RepositoryError.serverError(message: commonDTO.message)
        }

        return userDTO.toDomain()
    }

    func deleteAccount() async throws {
        let response = try await adapter.request(UserAPI.deleteAccount)

        let commonDTO = try JSONDecoder().decode(
            CommonDTO<EmptyResult>.self,
            from: response.data
        )

        guard commonDTO.isSuccess else {
            throw RepositoryError.serverError(message: commonDTO.message)
        }
    }
}

// MARK: - RepositoryError

enum RepositoryError: Error, LocalizedError {
    case serverError(message: String?)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message ?? "서버 에러"
        case .decodingError:
            return "데이터 파싱 실패"
        }
    }
}
```

### Step 5: UseCase Protocol 정의

**위치**: `Features/{Feature}/Domain/UseCases/`

```swift
// Features/User/Domain/UseCases/GetUserProfileUseCaseProtocol.swift
import Foundation

/// 사용자 프로필 조회 UseCase Protocol
protocol GetUserProfileUseCaseProtocol {
    /// 내 프로필 조회
    func execute() async throws -> User
}
```

### Step 6: UseCase 구현

**위치**: `Features/{Feature}/Domain/UseCases/Implementations/`

```swift
// Features/User/Domain/UseCases/Implementations/GetUserProfileUseCase.swift
import Foundation

final class GetUserProfileUseCase: GetUserProfileUseCaseProtocol {
    // MARK: - Property

    private let repository: UserRepositoryProtocol

    // MARK: - Initializer

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - GetUserProfileUseCaseProtocol

    func execute() async throws -> User {
        // 비즈니스 로직이 필요하다면 여기에 추가
        // 예: 캐싱, 검증, 데이터 가공 등
        try await repository.getMe()
    }
}
```

### Step 7: DIContainer에 등록

**위치**: `Core/DIContainer/DIContainer.swift`

```swift
// DIContainer.swift
import Foundation

@Observable
final class DIContainer {
    // MARK: - Singleton

    static let shared = DIContainer()

    // MARK: - Network

    private(set) lazy var networkClient: NetworkClient = {
        AuthSystemFactory.makeNetworkClient(
            baseURL: URL(string: "https://api.umc.com")!
        )
    }()

    private(set) lazy var moyaAdapter: MoyaNetworkAdapter = {
        MoyaNetworkAdapter(
            networkClient: networkClient,
            baseURL: URL(string: "https://api.umc.com")!
        )
    }()

    // MARK: - Repositories

    private(set) lazy var userRepository: UserRepositoryProtocol = {
        UserRepository(adapter: moyaAdapter)
    }()

    // MARK: - UseCases

    func getUserProfileUseCase() -> GetUserProfileUseCaseProtocol {
        GetUserProfileUseCase(repository: userRepository)
    }

    func updateUserProfileUseCase() -> UpdateUserProfileUseCaseProtocol {
        UpdateUserProfileUseCase(repository: userRepository)
    }

    private init() {}
}
```

### Step 8: ViewModel 작성

**위치**: `Features/{Feature}/Presentation/ViewModels/`

```swift
// Features/User/Presentation/ViewModels/UserProfileViewModel.swift
import Foundation

@Observable
final class UserProfileViewModel {
    // MARK: - Property

    private let getUserProfileUseCase: GetUserProfileUseCaseProtocol
    private let updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol

    // Loadable로 비동기 상태 관리
    private(set) var userState: Loadable<User> = .idle

    // MARK: - Initializer

    init(
        getUserProfileUseCase: GetUserProfileUseCaseProtocol,
        updateUserProfileUseCase: UpdateUserProfileUseCaseProtocol
    ) {
        self.getUserProfileUseCase = getUserProfileUseCase
        self.updateUserProfileUseCase = updateUserProfileUseCase
    }

    // MARK: - Action

    @MainActor
    func loadProfile() async {
        userState = .loading

        do {
            let user = try await getUserProfileUseCase.execute()
            userState = .loaded(user)
        } catch let error as DomainError {
            // 도메인 에러 → 인라인 표시 (Loadable)
            userState = .failed(.domain(error))
        } catch let error as NetworkError {
            // 네트워크 에러 → AppError.network로 래핑
            userState = .failed(.network(error))
        } catch {
            // 기타 에러 → unknown
            userState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    @MainActor
    func updateProfile(name: String, bio: String) async {
        do {
            let updatedUser = try await updateUserProfileUseCase.execute(
                name: name,
                bio: bio
            )
            userState = .loaded(updatedUser)
        } catch let error as NetworkError {
            userState = .failed(.network(error))
        } catch {
            userState = .failed(.unknown(message: error.localizedDescription))
        }
    }
}
```

### Step 9: View 작성

**위치**: `Features/{Feature}/Presentation/Views/`

```swift
// Features/User/Presentation/Views/UserProfileView.swift
import SwiftUI

struct UserProfileView: View {
    // MARK: - Property

    @State private var viewModel: UserProfileViewModel
    @Environment(\.di) private var di

    // MARK: - Initializer

    init(container: DIContainer) {
        _viewModel = State(initialValue: UserProfileViewModel(
            getUserProfileUseCase: container.getUserProfileUseCase(),
            updateUserProfileUseCase: container.updateUserProfileUseCase()
        ))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.userState {
            case .idle:
                Color.clear
                    .task {
                        await viewModel.loadProfile()
                    }

            case .loading:
                LoadingView(.home(.seasonLoading))

            case .loaded(let user):
                UserProfileContentView(user: user) {
                    await viewModel.updateProfile(
                        name: "New Name",
                        bio: "New Bio"
                    )
                }

            case .failed(let error):
                ErrorView(error: error) {
                    await viewModel.loadProfile()
                }
            }
        }
        .navigationTitle("프로필")
    }
}

// MARK: - Content View

struct UserProfileContentView: View {
    let user: User
    let onUpdate: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(user.name)
                .font(.title)

            Text(user.email)
                .font(.subheadline)

            if let bio = user.bio {
                Text(bio)
                    .font(.body)
            }

            Button("프로필 수정") {
                Task {
                    await onUpdate()
                }
            }
        }
        .padding()
    }
}
```

---

## 완전한 예제: User API

위의 모든 단계를 따라 구현한 전체 예제는 다음 파일들을 참고하세요:

```
Features/User/
├── Data/
│   ├── DataSources/
│   │   └── UserAPI.swift
│   ├── DTOs/
│   │   └── UserDTO.swift
│   └── Repositories/
│       └── UserRepository.swift
├── Domain/
│   ├── Interfaces/
│   │   └── UserRepositoryProtocol.swift
│   ├── Models/
│   │   └── User.swift
│   └── UseCases/
│       ├── GetUserProfileUseCaseProtocol.swift
│       ├── UpdateUserProfileUseCaseProtocol.swift
│       └── Implementations/
│           ├── GetUserProfileUseCase.swift
│           └── UpdateUserProfileUseCase.swift
└── Presentation/
    ├── ViewModels/
    │   └── UserProfileViewModel.swift
    └── Views/
        └── UserProfileView.swift
```

---

## 에러 처리

### Loadable 패턴 (인라인 에러)

화면 내에서 에러를 표시할 때 사용합니다.

```swift
@Observable
final class SomeViewModel {
    private(set) var dataState: Loadable<Data> = .idle

    @MainActor
    func fetch() async {
        dataState = .loading

        do {
            let data = try await useCase.execute()
            dataState = .loaded(data)
        } catch let error as DomainError {
            // 도메인 에러 → 화면 내 표시 (인라인)
            dataState = .failed(.domain(error))
        } catch let error as NetworkError {
            // 네트워크 에러 → 화면 내 표시 (인라인)
            dataState = .failed(.network(error))
        } catch {
            // 기타 에러
            dataState = .failed(.unknown(message: error.localizedDescription))
        }
    }
}

// View
switch viewModel.dataState {
case .idle: Color.clear
case .loading: ProgressView()
case .loaded(let data): ContentView(data: data)
case .failed(let error): ErrorView(error: error, retry: { await viewModel.fetch() })
}
```

### ErrorHandler (전역 Alert 에러)

작업 흐름을 중단하고 즉각적인 사용자 액션이 필요한 경우 사용합니다.

```swift
@Observable
final class SomeViewModel {
    private let errorHandler: ErrorHandler

    @MainActor
    func criticalAction() async {
        do {
            try await useCase.execute()
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "User",
                action: "criticalAction",
                retryAction: { [weak self] in
                    await self?.criticalAction()
                }
            ))
        }
    }
}
```

### 네트워크 에러 종류

NetworkClient(Actor 기반)에서 발생하는 에러 타입입니다.

```swift
// NetworkError - Actor 기반 네트워크 클라이언트 에러
enum NetworkError: Error, Sendable, Equatable {
    case unauthorized                         // 인증 토큰 없음 (401)
    case tokenRefreshFailed(reason: String?)  // 토큰 갱신 실패 (Equatable 준수)
    case noRefreshToken                       // 리프레시 토큰 없음
    case requestFailed(statusCode: Int, data: Data?)  // API 요청 실패
    case invalidResponse                      // 잘못된 응답
    case maxRetryExceeded                     // 재시도 횟수 초과
}

// 에러 처리 예시
do {
    let data = try await networkClient.request(urlRequest)
} catch let error as NetworkError {
    switch error {
    case .unauthorized:
        // 로그인 필요
        navigateToLogin()

    case .tokenRefreshFailed(let reason):
        // 토큰 갱신 실패 → 재로그인
        print("갱신 실패 원인: \(reason ?? "알 수 없음")")
        navigateToLogin()

    case .noRefreshToken:
        // 리프레시 토큰 없음
        navigateToLogin()

    case .requestFailed(let statusCode, _):
        // 서버 에러
        if statusCode == 404 {
            print("리소스 없음")
        } else if statusCode >= 500 {
            print("서버 에러")
        }

    case .invalidResponse:
        // 네트워크 연결 문제
        print("네트워크 연결 확인")

    case .maxRetryExceeded:
        // 재시도 횟수 초과
        print("재로그인 필요")
    }
}
```

#### NetworkError vs APIError

| 에러 타입 | 발생 위치 | 용도 |
|----------|---------|------|
| **NetworkError** | NetworkClient (Actor 기반) | JWT 인증, 토큰 갱신, 네트워크 계층 |
| **APIError** | MoyaProvider (Moya 기반) | HTTP 응답 에러, 디코딩 에러 |

두 에러는 모두 `AppError`로 통합됩니다:
```swift
enum AppError {
    case network(NetworkError)  // Actor 기반
    case api(APIError)          // Moya 기반
    // ...
}
```

---

## 테스트 작성

### Repository 테스트

```swift
import XCTest
@testable import AppProduct

final class UserRepositoryTests: XCTestCase {
    var sut: UserRepository!
    var mockAdapter: MockMoyaNetworkAdapter!

    override func setUp() {
        super.setUp()
        mockAdapter = MockMoyaNetworkAdapter()
        sut = UserRepository(adapter: mockAdapter)
    }

    func test_getMe_성공() async throws {
        // Given
        let expectedUser = User(
            id: UserID(value: 1),
            name: "Test User",
            email: "test@example.com",
            bio: "Test Bio",
            profileImageUrl: nil,
            createdAt: Date()
        )
        mockAdapter.mockResponse = createMockResponse(user: expectedUser)

        // When
        let user = try await sut.getMe()

        // Then
        XCTAssertEqual(user.name, expectedUser.name)
        XCTAssertEqual(user.email, expectedUser.email)
    }
}
```

### UseCase 테스트

```swift
final class GetUserProfileUseCaseTests: XCTestCase {
    var sut: GetUserProfileUseCase!
    var mockRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = GetUserProfileUseCase(repository: mockRepository)
    }

    func test_execute_성공() async throws {
        // Given
        let expectedUser = User(...)
        mockRepository.mockUser = expectedUser

        // When
        let user = try await sut.execute()

        // Then
        XCTAssertEqual(user.name, expectedUser.name)
    }
}
```

### ViewModel 테스트

```swift
@MainActor
final class UserProfileViewModelTests: XCTestCase {
    var sut: UserProfileViewModel!
    var mockUseCase: MockGetUserProfileUseCase!

    override func setUp() {
        super.setUp()
        mockUseCase = MockGetUserProfileUseCase()
        sut = UserProfileViewModel(
            getUserProfileUseCase: mockUseCase,
            updateUserProfileUseCase: MockUpdateUserProfileUseCase()
        )
    }

    func test_loadProfile_성공() async {
        // Given
        let expectedUser = User(...)
        mockUseCase.mockUser = expectedUser

        // When
        await sut.loadProfile()

        // Then
        if case .loaded(let user) = sut.userState {
            XCTAssertEqual(user.name, expectedUser.name)
        } else {
            XCTFail("Expected loaded state")
        }
    }
}
```

---

## 체크리스트

새로운 API를 추가할 때 다음 항목들을 확인하세요:

- [ ] Moya TargetType 정의 (DataSources)
- [ ] DTO 정의 및 `toDomain()` 구현 (DTOs)
- [ ] Repository Protocol 정의 (Domain/Interfaces)
- [ ] Repository 구현 (Data/Repositories)
- [ ] UseCase Protocol 정의 (Domain/UseCases)
- [ ] UseCase 구현 (Domain/UseCases/Implementations)
- [ ] DIContainer에 등록
- [ ] ViewModel 작성 (Loadable 패턴 사용)
- [ ] View 작성 (Environment DI 사용)
- [ ] 에러 처리 (Loadable vs ErrorHandler 선택)
- [ ] 유닛 테스트 작성

---

## 참고 자료

- [CLAUDE.md](./CLAUDE.md) - 프로젝트 아키텍처 및 코딩 스타일
- [NetworkClient.swift](./AppProduct/AppProduct/Core/NetworkAdapter/NetworkClient/NetworkClient.swift) - JWT 인증 및 토큰 갱신
- [MoyaNetworkAdapter.swift](./AppProduct/AppProduct/Core/NetworkAdapter/TokenRefreshService/MoyaNetworkAdapter.swift) - Moya 어댑터
- [Loadable.swift](./AppProduct/AppProduct/Core/Common/Error/Loadable.swift) - 비동기 상태 관리

---

## 자주 묻는 질문 (FAQ)

### Q1. Repository에서 왜 Protocol을 사용하나요?

**A**: SOLID 원칙 중 의존성 역전 원칙(DIP)을 따르기 위함입니다. UseCase가 구체적인 구현(Repository)에 의존하지 않고 추상화(Protocol)에 의존하면:
- 테스트 시 Mock으로 쉽게 교체 가능
- 구현체 변경 시 UseCase 코드 수정 불필요
- 여러 구현체 공존 가능 (로컬 캐시, 원격 서버 등)

### Q2. UseCase가 꼭 필요한가요? Repository를 직접 호출하면 안 되나요?

**A**: UseCase는 비즈니스 로직을 담당합니다. 간단한 CRUD라면 Repository 호출만 하지만, 다음과 같은 경우 UseCase가 필요합니다:
- 여러 Repository 조합 (User + Post Repository)
- 데이터 검증 및 가공
- 캐싱 로직
- 도메인 규칙 적용

### Q3. ViewModel에서 DIContainer를 직접 주입받지 않고 UseCase를 주입받는 이유는?

**A**: 의존성 명시화를 위함입니다:
- ViewModel이 필요한 UseCase만 주입받음
- 테스트 시 필요한 Mock만 생성
- DIContainer 전체 의존성 노출 방지

### Q4. Loadable과 ErrorHandler를 언제 사용하나요?

**A**:
- **Loadable**: 화면 내 에러 표시 (리스트 로딩 실패, 도메인 에러 등)
- **ErrorHandler**: 작업 중단 필요 (세션 만료, 권한 오류, 네트워크 끊김 등)

### Q5. CommonDTO는 무엇인가요?

**A**: 서버의 공통 응답 포맷입니다:
```json
{
  "isSuccess": true,
  "code": "200",
  "message": "성공",
  "result": { /* 실제 데이터 */ }
}
```

모든 API 응답이 이 형식을 따르므로, `CommonDTO<T>`를 사용하여 파싱합니다.
