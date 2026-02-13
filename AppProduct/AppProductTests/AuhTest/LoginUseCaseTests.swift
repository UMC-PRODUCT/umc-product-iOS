//
//  LoginUseCaseTests.swift
//  AppProductTests
//
//  Created by jaewon Lee on 2/9/26.
//

import Testing
@testable import AppProduct

@Suite("LoginUseCase Tests")
@MainActor
struct LoginUseCaseTests {
    @Test("카카오_로그인_기존회원_토큰_저장됨")
    func test_카카오_로그인_기존회원_토큰_저장됨() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        let expectedTokenPair = TokenPair(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token"
        )
        repository.loginKakaoResult = .success(.existingMember(tokenPair: expectedTokenPair))

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        _ = try await sut.executeKakao(accessToken: "kakao-token", email: "test@example.com")

        let savedAccessToken = await tokenStore.savedAccessToken
        let savedRefreshToken = await tokenStore.savedRefreshToken
        let saveCallCount = await tokenStore.getSaveCallCount()

        #expect(savedAccessToken == "test-access-token")
        #expect(savedRefreshToken == "test-refresh-token")
        #expect(saveCallCount == 1)
    }

    @Test("카카오_로그인_신규회원_토큰_저장_안됨")
    func test_카카오_로그인_신규회원_토큰_저장_안됨() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        repository.loginKakaoResult = .success(.newMember(verificationToken: "verification-token"))

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        _ = try await sut.executeKakao(accessToken: "kakao-token", email: "test@example.com")

        let saveCallCount = await tokenStore.getSaveCallCount()

        #expect(saveCallCount == 0)
    }

    @Test("카카오_로그인_결과_올바르게_반환")
    func test_카카오_로그인_결과_올바르게_반환() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        let expectedTokenPair = TokenPair(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token"
        )
        let expectedResult = OAuthLoginResult.existingMember(tokenPair: expectedTokenPair)
        repository.loginKakaoResult = .success(expectedResult)

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        let result = try await sut.executeKakao(accessToken: "kakao-token", email: "test@example.com")

        #expect(result == expectedResult)
    }

    @Test("카카오_로그인_파라미터_전달_확인")
    func test_카카오_로그인_파라미터_전달_확인() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        repository.loginKakaoResult = .success(.newMember(verificationToken: "token"))

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        _ = try await sut.executeKakao(accessToken: "kakao-access-token", email: "user@example.com")

        #expect(repository.loginKakaoCalled == true)
        #expect(repository.loginKakaoAccessToken == "kakao-access-token")
        #expect(repository.loginKakaoEmail == "user@example.com")
    }

    @Test("애플_로그인_에러_전파")
    func test_애플_로그인_에러_전파() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        let expectedError = RepositoryError.serverError(code: "501", message: "Server error")
        repository.loginAppleResult = .failure(expectedError)

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        await #expect(throws: RepositoryError.self) {
            try await sut.executeApple(authorizationCode: "apple-auth-code")
        }

        let saveCallCount = await tokenStore.getSaveCallCount()
        #expect(saveCallCount == 0)
    }

    @Test("애플_로그인_성공시_토큰_저장")
    func test_애플_로그인_성공시_토큰_저장() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        let expectedTokenPair = TokenPair(
            accessToken: "apple-access-token",
            refreshToken: "apple-refresh-token"
        )
        repository.loginAppleResult = .success(.existingMember(tokenPair: expectedTokenPair))

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        _ = try await sut.executeApple(authorizationCode: "apple-auth-code")

        let savedAccessToken = await tokenStore.savedAccessToken
        let savedRefreshToken = await tokenStore.savedRefreshToken
        let saveCallCount = await tokenStore.getSaveCallCount()

        #expect(savedAccessToken == "apple-access-token")
        #expect(savedRefreshToken == "apple-refresh-token")
        #expect(saveCallCount == 1)
    }

    @Test("리포지토리_에러시_UseCase_에러_전파")
    func test_리포지토리_에러시_UseCase_에러_전파() async throws {
        let tokenStore = SpyTokenStore()
        let repository = SpyAuthRepository()
        let expectedError = RepositoryError.decodingError(detail: "Failed to decode response")
        repository.loginKakaoResult = .failure(expectedError)

        let sut = LoginUseCase(repository: repository, tokenStore: tokenStore)

        await #expect(throws: RepositoryError.self) {
            try await sut.executeKakao(accessToken: "kakao-token", email: "test@example.com")
        }
    }
}

// MARK: - Test Doubles

final class SpyAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    var loginKakaoResult: Result<OAuthLoginResult, Error> = .success(.newMember(verificationToken: "default"))
    var loginAppleResult: Result<OAuthLoginResult, Error> = .success(.newMember(verificationToken: "default"))

    var loginKakaoCalled = false
    var loginKakaoAccessToken: String?
    var loginKakaoEmail: String?

    var loginAppleCalled = false
    var loginAppleAuthCode: String?

    func loginKakao(accessToken: String, email: String) async throws -> OAuthLoginResult {
        loginKakaoCalled = true
        loginKakaoAccessToken = accessToken
        loginKakaoEmail = email
        return try loginKakaoResult.get()
    }

    func loginApple(authorizationCode: String) async throws -> OAuthLoginResult {
        loginAppleCalled = true
        loginAppleAuthCode = authorizationCode
        return try loginAppleResult.get()
    }

    func renewToken(refreshToken: String) async throws -> TokenPair {
        fatalError("Not needed in LoginUseCase tests")
    }

    func getMyOAuth() async throws -> [MemberOAuth] {
        fatalError("Not needed in LoginUseCase tests")
    }

    func sendEmailVerification(email: String) async throws -> String {
        fatalError("Not needed in LoginUseCase tests")
    }

    func verifyEmailCode(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        fatalError("Not needed in LoginUseCase tests")
    }

    func register(request: RegisterRequestDTO) async throws -> Int {
        fatalError("Not needed in LoginUseCase tests")
    }

    func getSchools() async throws -> [School] {
        fatalError("Not needed in LoginUseCase tests")
    }

    func getTerms(termsType: String) async throws -> Terms {
        fatalError("Not needed in LoginUseCase tests")
    }
}

actor SpyTokenStore: TokenStore {
    var savedAccessToken: String?
    var savedRefreshToken: String?
    private var _saveCallCount = 0

    func getAccessToken() async -> String? {
        savedAccessToken
    }

    func getRefreshToken() async -> String? {
        savedRefreshToken
    }

    func save(accessToken: String, refreshToken: String) async throws {
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
        _saveCallCount += 1
    }

    func clear() async throws {
        savedAccessToken = nil
        savedRefreshToken = nil
    }

    func getSaveCallCount() -> Int {
        _saveCallCount
    }
}
