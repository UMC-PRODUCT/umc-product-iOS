//
//  FetchMyOAuthUseCaseTests.swift
//  AppProductTests
//
//  Created by jaewon Lee on 2/9/26.
//

import Testing
@testable import AppProduct

@Suite("FetchMyOAuthUseCase Tests")
@MainActor
struct FetchMyOAuthUseCaseTests {

    // MARK: - Test: OAuth 정보 조회 성공

    @Test
    func test_OAuth_정보_조회_성공() async throws {
        // Given
        let expectedOAuth = MemberOAuth(
            memberOAuthId: 1,
            memberId: 100,
            provider: "KAKAO"
        )
        let repository = StubOAuthRepository()
        repository.getMyOAuthResult = .success([expectedOAuth])
        let sut = FetchMyOAuthUseCase(repository: repository)

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 1)
        #expect(result[0].memberOAuthId == 1)
        #expect(result[0].memberId == 100)
        #expect(result[0].provider == "KAKAO")
    }

    // MARK: - Test: 빈 OAuth 목록 반환

    @Test
    func test_빈_OAuth_목록_반환() async throws {
        // Given
        let repository = StubOAuthRepository()
        repository.getMyOAuthResult = .success([])
        let sut = FetchMyOAuthUseCase(repository: repository)

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - Test: 다중 OAuth 정보 반환

    @Test
    func test_다중_OAuth_정보_반환() async throws {
        // Given
        let oauths = [
            MemberOAuth(memberOAuthId: 1, memberId: 100, provider: "KAKAO"),
            MemberOAuth(memberOAuthId: 2, memberId: 100, provider: "APPLE"),
            MemberOAuth(memberOAuthId: 3, memberId: 100, provider: "GOOGLE")
        ]
        let repository = StubOAuthRepository()
        repository.getMyOAuthResult = .success(oauths)
        let sut = FetchMyOAuthUseCase(repository: repository)

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 3)
        #expect(result[0].provider == "KAKAO")
        #expect(result[1].provider == "APPLE")
        #expect(result[2].provider == "GOOGLE")
    }

    // MARK: - Test: 서버 에러 전파

    @Test
    func test_서버_에러_전파() async throws {
        // Given
        let serverError = RepositoryError.serverError(
            code: "AUTH_001",
            message: "OAuth 조회 실패"
        )
        let repository = StubOAuthRepository()
        repository.getMyOAuthResult = .failure(serverError)
        let sut = FetchMyOAuthUseCase(repository: repository)

        // When & Then
        await #expect(throws: RepositoryError.self) {
            try await sut.execute()
        }
    }

    // MARK: - Test: 디코딩 에러 전파

    @Test
    func test_디코딩_에러_전파() async throws {
        // Given
        let decodingError = RepositoryError.decodingError(
            detail: "Invalid OAuth data format"
        )
        let repository = StubOAuthRepository()
        repository.getMyOAuthResult = .failure(decodingError)
        let sut = FetchMyOAuthUseCase(repository: repository)

        // When & Then
        await #expect(throws: RepositoryError.self) {
            try await sut.execute()
        }
    }
}

// MARK: - Test Doubles

final class StubOAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    var getMyOAuthResult: Result<[MemberOAuth], Error> = .success([])

    func loginKakao(accessToken: String, email: String) async throws -> OAuthLoginResult {
        fatalError("Not implemented for testing")
    }

    func loginApple(authorizationCode: String) async throws -> OAuthLoginResult {
        fatalError("Not implemented for testing")
    }

    func renewToken(refreshToken: String) async throws -> TokenPair {
        fatalError("Not implemented for testing")
    }

    func getMyOAuth() async throws -> [MemberOAuth] {
        try getMyOAuthResult.get()
    }

    func sendEmailVerification(email: String) async throws -> String {
        fatalError("Not implemented for testing")
    }

    func verifyEmailCode(emailVerificationId: String, verificationCode: String) async throws -> String {
        fatalError("Not implemented for testing")
    }

    func register(request: RegisterRequestDTO) async throws -> Int {
        fatalError("Not implemented for testing")
    }

    func getSchools() async throws -> [School] {
        fatalError("Not implemented for testing")
    }

    func getTerms(termsType: String) async throws -> Terms {
        fatalError("Not implemented for testing")
    }
}
