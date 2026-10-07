//
//  NetworkClientTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 4/25/26.
//

import Foundation
import Darwin
import Moya
import Testing
import UMCFoundation
@testable import CoreNetwork

@Suite("NetworkClient", .serialized)
@MainActor
struct NetworkClientTests {

    // MARK: - Fixtures

    private let testURL = URL(string: "https://api.umc.test/api/v1/me")!

    private func makeClient(
        store: MockTokenStore,
        refresh: MockTokenRefreshService,
        maxRetryCount: Int = 1
    ) -> NetworkClient {
        StubURLProtocol.reset()
        let session = makeStubSession()
        return NetworkClient(
            session: session,
            tokenStore: store,
            refreshService: refresh,
            authPolicy: DefaultAuthenticationPolicy(),
            maxRetryCount: maxRetryCount
        )
    }

    // MARK: - isLoggedIn / logout

    @Test("토큰이 있으면 isLoggedIn이 true다")
    func isLoggedInTrue() async {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        let loggedIn = await client.isLoggedIn()
        #expect(loggedIn)
    }

    @Test("토큰이 없으면 isLoggedIn이 false다")
    func isLoggedInFalse() async {
        let store = MockTokenStore()
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        let loggedIn = await client.isLoggedIn()
        #expect(!loggedIn)
    }

    @Test("logout 호출 시 tokenStore.clear()가 1회 호출된다")
    func logoutClearsTokens() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        try await client.logout()

        let clearCount = await store.clearCallCount
        let access = await store.accessToken
        #expect(clearCount == 1)
        #expect(access == nil)
    }

    /// 로그아웃이 토큰만 지우고 세션 AppStorage를 남기면, 다음 계정이 프로필을 동기화하기
    /// 전까지 **이전 계정의 memberId**가 유효한 값처럼 읽힌다. 그 값으로 스코프되는
    /// 명함첩 등이 남의 데이터를 그대로 연다 (#1217).
    @Test("logout 호출 시 세션 단위 AppStorage 값이 함께 비워진다")
    func logoutClearsSessionScopedStorage() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)
        UserDefaults.standard.set("777", forKey: AppStorageKey.memberId)
        UserDefaults.standard.set(true, forKey: AppStorageKey.canAutoLogin)

        try await client.logout()

        #expect(AppStorageKey.memberIdString() == nil)
        #expect(!UserDefaults.standard.bool(forKey: AppStorageKey.canAutoLogin))
    }

    // MARK: - request: Authorization 주입

    @Test("인증 정책이 true이고 액세스 토큰이 있으면 Authorization 헤더가 주입된다")
    func injectsAuthorizationHeader() async throws {
        let store = MockTokenStore(accessToken: "ACCESS123", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data("{}".utf8), 200, nil) }

        let request = URLRequest(url: testURL)
        _ = try await client.request(request)

        let captured = try #require(StubURLProtocol.capturedRequests.first)
        #expect(captured.value(forHTTPHeaderField: "Authorization") == "Bearer ACCESS123")
    }

    // MARK: - 401 → refresh → retry

    @Test("401 응답 시 refresh 후 새 액세스 토큰으로 재시도하고 200을 반환한다")
    func refreshOn401AndRetry() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh)

        // 1번째 호출: 401, 2번째 호출(refresh 후): 200
        let callCount = LockedCounter()
        StubURLProtocol.handler = { _ in
            let n = callCount.increment()
            if n == 1 {
                return (Data(), 401, nil)
            } else {
                return (Data("{\"ok\":true}".utf8), 200, nil)
            }
        }

        let request = URLRequest(url: testURL)
        let (data, response) = try await client.request(request)

        #expect(response.statusCode == 200)
        #expect(String(data: data, encoding: .utf8) == "{\"ok\":true}")

        let refreshCalls = await refresh.callCount
        #expect(refreshCalls == 1)

        let stored = await store.accessToken
        #expect(stored == "NEW")

        // 두 번째 요청에서 새 토큰이 헤더에 들어가야 한다
        let secondRequest = StubURLProtocol.capturedRequests[1]
        #expect(secondRequest.value(forHTTPHeaderField: "Authorization") == "Bearer NEW")
    }

    @Test("401이 재시도 후에도 다시 발생하면 maxRetryExceeded를 throw한다")
    func maxRetryExceededAfterRetry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh, maxRetryCount: 1)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.maxRetryExceeded) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("분류되지 않은 갱신 오류는 세션 만료로 바꾸지 않는다")
    func unclassifiedRefreshFailurePropagates() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: MockRefreshError.invalidRefreshToken) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("갱신 중 네트워크가 끊기면 noNetwork를 throw하고 저장된 토큰은 유지한다")
    func transportFailureKeepsSession() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .transportFailure(URLError(.notConnectedToInternet))
        )
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.noNetwork) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }

        let clearCount = await store.clearCallCount
        let refreshToken = await store.refreshToken
        #expect(clearCount == 0)
        #expect(refreshToken == "REFRESH")
    }

    @Test("갱신 요청이 타임아웃되면 timeout을 throw한다")
    func transportTimeoutIsNotSessionExpiry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .transportFailure(URLError(.timedOut)))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.timeout) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("서버가 리프레시 토큰을 거부(401)하면 tokenRefreshFailed를 throw한다")
    func serverRejectionBecomesTokenRefreshFailed() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .rejectedByServer(statusCode: 401))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(
            throws: NetworkError.tokenRefreshFailed(reason: "서버 에러 (status: 401)")
        ) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("갱신 API가 5xx면 세션 만료가 아니라 requestFailed로 전파된다")
    func serverOutageIsNotSessionExpiry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .rejectedByServer(statusCode: 503))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.requestFailed(statusCode: 503, data: nil)) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("리프레시 토큰이 없으면 NetworkError.noRefreshToken을 throw한다")
    func noRefreshTokenError() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: nil)
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.self) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    // MARK: - Single-flight refresh

    @Test("동시 다발적 401에서도 토큰 갱신은 단 1회만 실행된다 (single-flight)")
    func singleFlightRefresh() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .delayedSuccess(
                TokenPair(accessToken: "NEW", refreshToken: "NEW_R"),
                nanoseconds: 80_000_000  // 80ms
            )
        )
        let client = makeClient(store: store, refresh: refresh)

        // 첫 요청은 401, 이후엔 200
        let callCount = LockedCounter()
        StubURLProtocol.handler = { _ in
            let n = callCount.increment()
            if n <= 5 { // 처음 5개의 동시 요청은 모두 401
                return (Data(), 401, nil)
            } else {
                return (Data("{}".utf8), 200, nil)
            }
        }

        async let r1 = client.request(URLRequest(url: testURL))
        async let r2 = client.request(URLRequest(url: testURL))
        async let r3 = client.request(URLRequest(url: testURL))
        async let r4 = client.request(URLRequest(url: testURL))
        async let r5 = client.request(URLRequest(url: testURL))

        let results = try await [r1, r2, r3, r4, r5]
        #expect(results.allSatisfy { $0.1.statusCode == 200 })

        let refreshCalls = await refresh.callCount
        #expect(refreshCalls == 1, "동시 401에도 refresh는 1회만 호출되어야 한다 — 실제: \(refreshCalls)")
    }

    // MARK: - forceRefreshToken

    @Test("forceRefreshToken은 새 토큰 쌍을 저장하고 반환한다")
    func forceRefreshSavesAndReturns() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let newPair = TokenPair(accessToken: "NEW_A", refreshToken: "NEW_R")
        let refresh = MockTokenRefreshService(behavior: .success(newPair))
        let client = makeClient(store: store, refresh: refresh)

        let result = try await client.forceRefreshToken()

        #expect(result == newPair)

        let savedAccess = await store.accessToken
        let savedRefresh = await store.refreshToken
        #expect(savedAccess == "NEW_A")
        #expect(savedRefresh == "NEW_R")
    }

    // MARK: - Decodable overload

    @Test("Decodable 오버로드는 응답 JSON을 자동 디코딩한다")
    func decodableOverloadDecodes() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in
            (Data("{\"id\":7,\"name\":\"jeong\"}".utf8), 200, nil)
        }

        let dto: SampleDTO = try await client.request(URLRequest(url: testURL))

        #expect(dto.id == 7)
        #expect(dto.name == "jeong")
    }

    // MARK: - Non-2xx error

    @Test("2xx 외 응답은 NetworkError.requestFailed로 변환된다")
    func nonSuccessStatusCodeFails() async {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 500, nil) }

        await #expect(throws: NetworkError.requestFailed(statusCode: 500, data: nil)) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("일반 요청의 전송 오류도 앱의 재시도 가능한 오류로 변환한다")
    func requestTransportErrorIsMapped() async {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.networkUnavailable))
        let client = makeClient(store: store, refresh: refresh)
        StubURLProtocol.handler = { _ in throw URLError(.timedOut) }

        await #expect(throws: NetworkError.timeout) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
        #expect(await client.isLoggedIn())
    }

    @Test("Moya 공개 요청은 주입한 세션을 사용하고 Bearer 토큰을 붙이지 않는다")
    func publicMoyaRequestUsesInjectedSession() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)
        let adapter = MoyaNetworkAdapter(networkClient: client, baseURL: testURL)
        StubURLProtocol.handler = { _ in (Data("public".utf8), 200, nil) }

        let response = try await adapter.requestWithoutAuth(HTTPTestTarget())

        #expect(response.data == Data("public".utf8))
        let request = try #require(StubURLProtocol.capturedRequests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(await refresh.callCount == 0)
    }

    @Test("Moya 공개 요청의 401은 갱신하지 않고 서버 응답을 보존한다")
    func publicMoyaUnauthorizedDoesNotRefresh() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)
        let adapter = MoyaNetworkAdapter(networkClient: client, baseURL: testURL)
        let body = Data("denied".utf8)
        StubURLProtocol.handler = { _ in (body, 401, nil) }

        do {
            _ = try await adapter.requestWithoutAuth(HTTPTestTarget())
            Issue.record("401 응답이 성공으로 처리되었습니다")
        } catch NetworkError.requestFailed(let statusCode, let data) {
            #expect(statusCode == 401)
            #expect(data == body)
        }
        #expect(StubURLProtocol.capturedRequests.count == 1)
        #expect(await refresh.callCount == 0)
        #expect(await client.isLoggedIn())
    }

    @Test("Moya는 쿼리, JSON 본문, 사용자 헤더와 Bearer 토큰을 함께 보존한다")
    func moyaCompositeRequestPreservesWireContract() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)
        let adapter = MoyaNetworkAdapter(networkClient: client, baseURL: testURL)
        StubURLProtocol.handler = { _ in (Data(), 204, nil) }
        let target = HTTPTestTarget(
            method: .post,
            task: .requestCompositeParameters(
                bodyParameters: ["name": "회원", "enabled": true],
                bodyEncoding: JSONEncoding.default,
                urlParameters: ["cursor": "42", "search": "a b"]
            )
        )

        _ = try await adapter.request(target)

        let request = try #require(StubURLProtocol.capturedRequests.first)
        let components = try #require(URLComponents(
            url: request.url!, resolvingAgainstBaseURL: false
        ))
        #expect(components.path == "/api/v1/example")
        #expect(components.queryItems?.contains(URLQueryItem(name: "cursor", value: "42")) == true)
        #expect(components.queryItems?.contains(
            URLQueryItem(name: "search", value: "a b")
        ) == true)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-Client") == "UMC")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer A")
        let body = try #require(request.httpBody ?? request.httpBodyStream?.readData())
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["name"] as? String == "회원")
        #expect(json["enabled"] as? Bool == true)
    }

    @Test("JSON Encodable 요청은 JSON Content-Type을 자동으로 지정한다")
    func moyaJSONEncodableSetsContentType() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)
        let adapter = MoyaNetworkAdapter(networkClient: client, baseURL: testURL)
        StubURLProtocol.handler = { _ in (Data(), 200, nil) }

        _ = try await adapter.request(HTTPTestTarget(
            method: .post,
            task: .requestJSONEncodable(HTTPTestBody(name: "회원"))
        ))

        let request = try #require(StubURLProtocol.capturedRequests.first)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("토큰 갱신은 기존 JSON 요청과 APIResponse 계약을 유지한다")
    func httpRefreshPreservesWireContract() async throws {
        StubURLProtocol.reset()
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "R")
        let client = AuthSystemFactory.makeNetworkClient(
            baseURL: URL(string: "https://api.umc.test")!,
            session: makeStubSession(),
            tokenStore: store
        )
        StubURLProtocol.handler = { _ in
            (Data("""
            {"success":true,"code":"200","message":"성공",
             "result":{"accessToken":"NEW","refreshToken":"NEW_R"}}
            """.utf8), 200, nil)
        }

        let pair = try await client.forceRefreshToken()

        #expect(pair == TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        let request = try #require(StubURLProtocol.capturedRequests.first)
        #expect(request.url?.path == "/api/v1/auth/token/renew")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        let body = try #require(request.httpBody ?? request.httpBodyStream?.readData())
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["refreshToken": "R"])
        #expect(await store.getAccessToken() == "NEW")
    }

    @Test("갱신 응답의 JSON 디코딩 오류는 세션을 만료시키지 않는다")
    func refreshDecodingFailureKeepsSession() async throws {
        StubURLProtocol.reset()
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "R")
        let client = AuthSystemFactory.makeNetworkClient(
            baseURL: URL(string: "https://api.umc.test")!,
            session: makeStubSession(),
            tokenStore: store
        )
        StubURLProtocol.handler = { _ in (Data("invalid JSON".utf8), 200, nil) }

        await #expect(throws: DecodingError.self) {
            _ = try await client.forceRefreshToken()
        }
        #expect(await store.getRefreshToken() == "R")
        #expect(await client.isLoggedIn())
    }

    @Test("갱신 토큰 저장 오류는 세션 만료로 바꾸지 않는다")
    func refreshStorageFailurePropagates() async {
        let client = NetworkClient(
            session: makeStubSession(),
            tokenStore: FailingTokenStore(),
            refreshService: MockTokenRefreshService(
                behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
            )
        )

        await #expect(throws: TestStoreError.saveFailed) {
            _ = try await client.forceRefreshToken()
        }
    }

    @Test(
        "갱신 HTTP 오류는 401·403만 세션 만료로 처리한다", arguments: [401, 403, 503]
    )
    func httpRefreshErrorsPreserveSessionMeaning(statusCode: Int) async throws {
        StubURLProtocol.reset()
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "R")
        let client = AuthSystemFactory.makeNetworkClient(
            baseURL: URL(string: "https://api.umc.test")!,
            session: makeStubSession(),
            tokenStore: store
        )
        let body = Data("server failure".utf8)
        StubURLProtocol.handler = { _ in (body, statusCode, nil) }

        do {
            _ = try await client.forceRefreshToken()
            Issue.record("오류 응답이 성공으로 처리되었습니다")
        } catch let error as NetworkError {
            if statusCode == 401 || statusCode == 403 {
                guard case .tokenRefreshFailed = error else {
                    Issue.record("갱신 거부가 세션 만료 오류로 변환되지 않았습니다")
                    return
                }
            } else {
                guard case .requestFailed(let actualStatus, let data) = error else {
                    Issue.record("서버 장애가 일반 요청 실패로 변환되지 않았습니다")
                    return
                }
                #expect(actualStatus == 503)
                #expect(data == body)
            }
        }
        #expect(await store.getRefreshToken() == "R")
        #expect(await client.isLoggedIn())
    }

    #if DEBUG
    @Test("앱 인증 필드는 실제 요청 본문과 curl 로그에서 가리고 전송 값은 유지한다")
    func appCredentialLogsAreRedacted() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)
        let secrets = [
            "authorizationCode": "test-apple-authorization-secret",
            "oAuthVerificationToken": "test-oauth-verification-secret",
            "emailVerificationToken": "test-email-verification-secret",
            "googleAccessToken": "test-google-access-secret",
            "kakaoAccessToken": "test-kakao-access-secret",
            "rawPassword": "test-raw-password-secret",
            "currentPassword": "test-current-password-secret",
            "newPassword": "test-new-password-secret",
            "verificationCode": "test-email-otp-secret",
            "code": "test-claim-code-secret"
        ]
        let body = try JSONSerialization.data(withJSONObject: secrets)
        StubURLProtocol.handler = { _ in (body, 200, nil) }
        var request = URLRequest(url: testURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let output = try await captureStandardOutput {
            _ = try await client.request(request)
        }

        #expect(output.contains("body:"))
        #expect(output.contains("curl:"))
        #expect(output.contains("[REDACTED]"))
        for (key, secret) in secrets {
            #expect(output.contains(key))
            #expect(!output.contains(secret))
        }
        let outgoing = try #require(StubURLProtocol.capturedRequests.first)
        let sentBody = try #require(outgoing.httpBody ?? outgoing.httpBodyStream?.readData())
        #expect(try JSONSerialization.jsonObject(with: sentBody) as? [String: String] == secrets)
    }
    #endif
}

// MARK: - Helpers

private struct SampleDTO: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
}

private struct HTTPTestBody: Encodable {
    let name: String
}

private struct HTTPTestTarget: TargetType {
    var method: Moya.Method = .get
    var task: Moya.Task = .requestPlain
    var baseURL: URL { URL(string: "https://api.umc.test")! }
    var path: String { "/api/v1/example" }
    var headers: [String: String]? { ["X-Client": "UMC"] }
}

private enum TestStoreError: Error, Equatable {
    case saveFailed
}

private struct FailingTokenStore: TokenStore {
    func getAccessToken() async -> String? { "OLD" }
    func getRefreshToken() async -> String? { "R" }
    func save(accessToken: String, refreshToken: String) async throws {
        throw TestStoreError.saveFailed
    }
    func clear() async throws {}
}

private extension InputStream {
    func readData() -> Data {
        open()
        defer { close() }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while hasBytesAvailable {
            let count = read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            result.append(contentsOf: buffer.prefix(count))
        }
        return result
    }
}

#if DEBUG
@MainActor
private func captureStandardOutput(
    operation: () async throws -> Void
) async throws -> String {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    defer { try? FileManager.default.removeItem(at: url) }
    let file = try FileHandle(forWritingTo: url)
    defer { try? file.close() }
    fflush(nil)
    let original = dup(STDOUT_FILENO)
    guard original >= 0 else { throw POSIXError(.EBADF) }
    defer { close(original) }
    guard dup2(file.fileDescriptor, STDOUT_FILENO) >= 0 else { throw POSIXError(.EBADF) }
    defer {
        fflush(nil)
        _ = dup2(original, STDOUT_FILENO)
    }
    try await operation()
    fflush(nil)
    return String(decoding: try Data(contentsOf: url), as: UTF8.self)
}
#endif

/// 동기화된 카운터 — handler 클로저가 multiple thread/queue에서 호출될 수 있으므로 락 필요
private final class LockedCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    func increment() -> Int {
        lock.lock(); defer { lock.unlock() }
        value += 1
        return value
    }
}
