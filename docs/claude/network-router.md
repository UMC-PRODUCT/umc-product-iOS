# Network Router (Moya) & 전송 계층 (Aquila)

> API Router 설계 규칙(DTO 캡슐화)과 CoreNetwork 전송 계층(Aquila) 경계에 대한 상세 레퍼런스.
> 핵심 요약은 `CLAUDE.md` 참고.

API Router는 **엔드포인트 메타데이터(Path / Method / Encoding)만** 책임집니다.
**파라미터 키 이름과 직렬화 규칙은 Request/Query DTO가 캡슐화**합니다.
적용 대상은 `UMCApp/Features/*/Data/Sources/Router/` 와 `UMCApp/Core/Network/Sources/*/…Router.swift` 다.
(`AppProduct/` 는 v2.2.0 동결 — 소급 적용하지 않는다.)

- 작성자: 제옹(euijjang97)

## 전송 계층 (Aquila) — #1562

HTTP 전송·토큰 갱신·Keychain 토큰 저장·STOMP·로깅은 SPM 패키지
[Aquila](https://github.com/JEONG-J/Aquila)(`Aquila` · `AquilaMoya`, 커밋 revision 고정)가 담당한다.
`CoreNetwork` 는 그 위에 **앱 전용 얇은 래퍼**만 둔다. Router·Repository 코드는 전과 같이
`MoyaNetworkAdapter.request(_:)` 만 호출하면 된다.

| CoreNetwork 타입 | 감싸는 Aquila 타입 | 역할 |
|------------------|-------------------|------|
| `NetworkClient` (actor) | `Aquila.NetworkClient` | `URLRequest` 전송, 401 → 토큰 갱신 후 1회 재시도(`maxRetryCount`), `forceRefreshToken`/`logout`/`isLoggedIn`. 갱신 실패 시 `AppSessionResetter` 가 세션 초기화 |
| `MoyaNetworkAdapter` | `AquilaMoya.MoyaNetworkAdapter` | Moya `TargetType` → `URLRequest` 변환 후 `NetworkClient` 로 전송. `request`(인증) / `requestWithoutAuth`(비인증) |
| `KeychainTokenStore` (actor) | `Aquila.KeychainTokenStore` | 토큰 쌍(`account: "tokenPair"`) 저장 + 레거시 `accessToken`/`refreshToken` 항목 자동 이전. access group 규약은 `build-and-modules.md` "공유 Keychain Access Group" |
| `TokenRefreshServiceImpl` | `Aquila.HTTPTokenRefreshService` | `POST api/v1/auth/token/renew` 로 갱신, `APIResponse<TokenResult>` 디코딩 |
| `DefaultAuthenticationPolicy` · `AuthenticationPolicy` | `Aquila.DefaultAuthenticationPolicy` 의 `typealias` | 어떤 요청에 Bearer 를 붙일지 결정. 앱 전용 정책이 필요하면 `Aquila.AuthenticationPolicy` 를 구현해 `NetworkClient(authPolicy:)` 로 넘긴다 |
| `StompConnection` · `StompEvent` · `StompConnectionError` | 동명 Aquila 타입의 `typealias` | 커뮤니티 실시간 스레드. `StompConnection.webSocketURL(base:)` 가 `/ws/websocket` 경로·`ws(s)` 스킴을 만든다 |
| `TokenPair` · `TokenStore` · `TokenRefreshService` · `KeychainError` | Aquila 프로토콜/타입 재노출 | 테스트 Mock 은 이 프로토콜을 구현 |

규칙:

1. **`import Aquila` / `import AquilaMoya` 는 `CoreNetwork` 소스·테스트에서만.** Feature Data·App 타겟은
   CoreNetwork 가 노출한 래퍼만 쓴다. (현재 0건 외부 import — 유지할 것)
2. **에러는 앱 타입으로 변환해 던진다.** `Aquila.NetworkError` 는 `NetworkClient.appError(from:)` 에서
   `UMCFoundation.NetworkError` 로 매핑된다. 새 Aquila 에러 case 가 생기면 이 매핑에 추가한다.
3. **인증 필드 로그 마스킹.** `NetworkClient.logger`(`Aquila.VerboseLogger(redactedKeys:)`)가 `authorizationCode`·
   `rawPassword`·`verificationCode`·각종 토큰 키를 가린다. 비밀번호·토큰·인증코드 성격의 **요청/응답 필드를
   새로 추가하면 이 목록에도 추가**한다.
4. **Aquila 를 올릴 때**는 `Tuist/Package.swift` 의 `revision` 과 `Package.resolved` 를 함께 갱신하고
   `make test-network` 로 단위+통합 테스트를 돌린다 (통합 테스트는 `AppProductTestServer/` 가 떠 있을 때만).

## 원칙

1. **Router의 `task` 안에 인라인 딕셔너리 금지**
   `["key": value, ...]` 형태로 파라미터 키와 값을 Router 안에 직접 작성하지 않습니다. key 문자열이 Router에 흩어지면 스펙 변경 시 모든 case를 뒤져야 합니다.
2. **Body → `Encodable` DTO + `.requestJSONEncodable(body)`**
3. **Query → DTO + `toParameters` + `.requestParameters(..., encoding: URLEncoding.queryString)`**
   Query DTO는 직렬화 책임을 `var toParameters: [String: Any]` computed property로 캡슐화합니다. 네이밍은 `toParameters`로 통일합니다 (`queryItems`는 표준 `[URLQueryItem]`을 연상시켜 오해 소지).
4. **Path 변수(`{id}`)는 case associated value로 받아 `path`에서만 사용** — 쿼리/바디와 섞지 않습니다.
5. **단일 path 변수만 받는 case (예: `case getDetail(id: Int)`)는 DTO 불필요** — 파라미터 컬렉션이 생기는 순간 DTO 분리.

## ❌ 안티패턴

```swift
// Router가 파라미터 키 이름까지 알고 있음
case .getNoticeReadStatusList(_, let cursorId, let filterType, let organizationIds, let status):
    return .requestParameters(
        parameters: [
            "cursorId": cursorId,
            "filterType": filterType,
            "organizationIds": organizationIds,
            "status": status
        ],
        encoding: URLEncoding.queryString
    )

case .addLink(_, let links):
    return .requestParameters(
        parameters: ["links": links],
        encoding: JSONEncoding.default
    )
```

## ✅ 권장 패턴

```swift
// 1. Query/Body DTO 정의
struct NoticeReadStatusListQuery: Encodable {
    let cursorId: Int
    let filterType: String
    let organizationIds: [Int]
    let status: String

    var toParameters: [String: Any] {
        [
            "cursorId": cursorId,
            "filterType": filterType,
            "organizationIds": organizationIds,
            "status": status
        ]
    }
}

struct AddLinkRequestDTO: Encodable {
    let links: [String]
}

// 2. Router는 DTO만 받아 위임
case .getNoticeReadStatusList(_, let query):
    return .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

case .addLink(_, let body):
    return .requestJSONEncodable(body)
```

## DTO 파일 위치

- Body: `Features/{Feature}/Data/Sources/DTOs/Request/{Name}RequestDTO.swift`
- Query: `Features/{Feature}/Data/Sources/DTOs/Request/{Name}Query.swift`
- Core 공용 엔드포인트(인가·회원 프로필·스토리지)는 `Core/Network/Sources/{Authorization,Member,Storage}/` 에
  Router·DTO·Repository 를 함께 둔다.

## 적용 범위

- **신규 라우터/엔드포인트**: 처음부터 DTO 분리.
- **기존 라우터**: 별도 마이그레이션 작업으로 진행 (기능 작업과 분리해 PR을 따로 연다).
