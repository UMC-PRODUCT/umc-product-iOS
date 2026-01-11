//
//  NetworkClientTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 1/10/26.

//  로컬 서버(localhost:8080)를 사용한 NetworkClient 통합 테스트
//  테스트 전 AppProductTestServer를 실행해야 합니다:
//  cd AppProductTestServer && swift run
//

import XCTest
@testable import AppProduct

// MARK: - Test TokenStore
actor TestTokenStore: TokenStore {
    private var accessToken: String?
    private var refreshToken: String?

    var saveCallCount = 0
    var clearCallCount = 0

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func getAccessToken() async -> String? {
        accessToken
    }

    func getRefreshToken() async -> String? {
        refreshToken
    }

    func save(accessToken: String, refreshToken: String) async throws {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveCallCount += 1
    }

    func clear() async throws {
        accessToken = nil
        refreshToken = nil
        clearCallCount += 1
    }

    func setTokens(access: String?, refresh: String?) {
        self.accessToken = access
        self.refreshToken = refresh
    }

    func getSaveCallCount() -> Int {
        saveCallCount
    }

    func getClearCallCount() -> Int {
        clearCallCount
    }
}

// MARK: - NetworkClient Tests
final class NetworkClientTests: XCTestCase {

    private let baseURL = URL(string: "http://localhost:8080")!

    private var tokenStore: TestTokenStore!
    private var refreshService: TokenRefreshServiceImpl!
    private var sut: NetworkClient!

    override func setUp() async throws {
        try await super.setUp()

        tokenStore = TestTokenStore(
            accessToken: "valid_access_token",
            refreshToken: "valid_refresh_token"
        )
        refreshService = TokenRefreshServiceImpl(baseURL: baseURL)

        sut = NetworkClient(
            session: .shared,
            tokenStore: tokenStore,
            refreshService: refreshService,
            authPolicy: DefaultAuthenticationPolicy(),
            maxRetryCount: 1
        )
    }

    override func tearDown() async throws {
        tokenStore = nil
        refreshService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Server Connection Tests

    func test_서버_연결_확인() async throws {
        // Given
        let url = baseURL
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await URLSession.shared.data(for: request)

        // Then
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        let responseString = String(data: data, encoding: .utf8)
        XCTAssertEqual(responseString, "It works!")
    }

    // MARK: - Public API Tests

    func test_공개_API_접근_성공() async throws {
        // Given
        let url = baseURL.appending(path: "public")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<String>.self, from: data)
        let isSuccess = dto.isSuccess
        let result = dto.result

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(result, "테스트 성공")
    }

    func test_테스트_API_접근_성공() async throws {
        // Given
        let url = baseURL.appending(path: "test")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<String>.self, from: data)
        let isSuccess = dto.isSuccess

        XCTAssertTrue(isSuccess)
    }

    // MARK: - Protected API Tests

    func test_보호된_API_유효한_토큰으로_접근_성공() async throws {
        // Given
        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<String>.self, from: data)
        let isSuccess = dto.isSuccess
        let result = dto.result

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(result, "보호 성공")
    }

    func test_유저_정보_조회_성공() async throws {
        // Given
        let url = baseURL.appending(path: "user")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<UserResult>.self, from: data)
        let isSuccess = dto.isSuccess
        let result = dto.result

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(result?.id, 1)
        XCTAssertEqual(result?.name, "Test User")
        XCTAssertEqual(result?.email, "test@jeong.com")
    }

    func test_유저_목록_조회_성공() async throws {
        // Given
        let url = baseURL.appending(path: "users")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<[UserResult]>.self, from: data)
        let isSuccess = dto.isSuccess
        let result = dto.result

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(result?.count, 3)
    }

    func test_게시글_목록_조회_성공() async throws {
        // Given
        let url = baseURL.appending(path: "posts")
        let request = URLRequest(url: url)

        // When
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let dto = try JSONDecoder().decode(CommonDTO<[PostResult]>.self, from: data)
        let isSuccess = dto.isSuccess
        let result = dto.result

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(result?.count, 3)
        XCTAssertEqual(result?.first?.title, "1번 post")
    }

    // MARK: - Token Refresh Tests

    func test_만료된_토큰으로_요청시_자동_갱신_후_재요청() async throws {
        // Given
        await tokenStore.setTokens(access: "expired_token", refresh: "valid_refresh_token")

        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)

        let oldAccessToken = await tokenStore.getAccessToken()

        // When - 401 → 토큰 갱신 → 재요청
        let (data, response) = try await sut.request(request)

        // Then
        XCTAssertEqual(response.statusCode, 200)

        let newAccessToken = await tokenStore.getAccessToken()
        XCTAssertNotEqual(oldAccessToken, newAccessToken, "토큰이 갱신되어야 합니다")
        XCTAssertTrue(newAccessToken?.hasPrefix("new_access_token_") ?? false)

        let dto = try JSONDecoder().decode(CommonDTO<String>.self, from: data)
        XCTAssertTrue(dto.isSuccess)

        let saveCount = await tokenStore.getSaveCallCount()
        XCTAssertEqual(saveCount, 1, "토큰이 저장되어야 합니다")
    }

    func test_토큰_갱신_후_새_리프레시_토큰도_저장됨() async throws {
        // Given
        await tokenStore.setTokens(access: "expired_token", refresh: "valid_refresh_token")

        let url = baseURL.appending(path: "user")
        let request = URLRequest(url: url)

        // When
        _ = try await sut.request(request)

        // Then
        let newRefreshToken = await tokenStore.getRefreshToken()
        XCTAssertTrue(newRefreshToken?.hasPrefix("new_refresh_token_") ?? false)
    }

    // MARK: - Error Handling Tests

    func test_리프레시_토큰_없을때_에러_발생() async throws {
        await tokenStore.setTokens(access: "expired_token", refresh: nil)

        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)
        
        do {
            _ = try await sut.request(request)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as NetworkError {
            if case .noRefreshToken = error {
            } else {
                XCTFail("noRefreshToken 에러가 발생해야 합니다: \(error)")
            }
        }
    }

    func test_리프레시_토큰_만료시_에러_발생() async throws {
        // Given
        await tokenStore.setTokens(access: "expired_token", refresh: "expired_token")

        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)
        
        do {
            _ = try await sut.request(request)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as NetworkError {
            if case .tokenRefreshFailed = error {
            } else {
                XCTFail("tokenRefreshFailed 에러가 발생해야 합니다: \(error)")
            }
        }
    }

    func test_리프레시_토큰_유효하지_않을때_에러_발생() async throws {
        await tokenStore.setTokens(access: "expired_token", refresh: "invalid_token")

        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)

        do {
            _ = try await sut.request(request)
            XCTFail("에러가 발생해야 합니다")
        } catch let error as NetworkError {
            if case .tokenRefreshFailed = error {
            } else {
                XCTFail("tokenRefreshFailed 에러가 발생해야 합니다: \(error)")
            }
        }
    }

    // MARK: - Logout Tests

    func test_로그아웃시_토큰_삭제() async throws {
        let accessTokenBefore = await tokenStore.getAccessToken()
        XCTAssertNotNil(accessTokenBefore)

        try await sut.logout()

        let accessTokenAfter = await tokenStore.getAccessToken()
        let refreshTokenAfter = await tokenStore.getRefreshToken()
        let clearCount = await tokenStore.getClearCallCount()

        XCTAssertNil(accessTokenAfter)
        XCTAssertNil(refreshTokenAfter)
        XCTAssertEqual(clearCount, 1)
    }

    // MARK: - isLoggedIn Tests

    func test_토큰_있으면_로그인_상태() async {
        let isLoggedIn = await sut.isLoggedIn()

        XCTAssertTrue(isLoggedIn)
    }

    func test_토큰_없으면_로그아웃_상태() async {
        await tokenStore.setTokens(access: nil, refresh: nil)

        let isLoggedIn = await sut.isLoggedIn()

        XCTAssertFalse(isLoggedIn)
    }

    // MARK: - Generic Decodable Tests

    func test_Decodable_타입으로_응답_파싱() async throws {
        let url = baseURL.appending(path: "user")
        let request = URLRequest(url: url)

        let response: CommonDTO<UserResult> = try await sut.request(request)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.result?.id, 1)
        XCTAssertEqual(response.result?.name, "Test User")
    }

    // MARK: - Concurrent Request Tests

    func test_동시_요청시_토큰_갱신_한번만_수행() async throws {
        
        await tokenStore.setTokens(access: "expired_token", refresh: "valid_refresh_token")

        let url = baseURL.appending(path: "protected")
        let request = URLRequest(url: url)

        async let result1 = sut.request(request)
        async let result2 = sut.request(request)
        async let result3 = sut.request(request)

        let results = try await [result1, result2, result3]

        for (_, response) in results {
            XCTAssertEqual(response.statusCode, 200)
        }
        
        let saveCount = await tokenStore.getSaveCallCount()
        XCTAssertEqual(saveCount, 1, "동시 요청에서도 토큰 갱신은 한 번만 수행되어야 합니다")
    }
}

// MARK: - Response Models

private struct UserResult: Codable {
    let id: Int
    let name: String
    let email: String
}

private struct PostResult: Codable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}
