//
//  MockAuthRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// Auth Repository Mock 구현체
///
/// 개발/테스트 환경에서 서버 없이 동작합니다.
final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    // MARK: - Function

    func loginKakao(
        accessToken: String,
        email: String
    ) async throws -> OAuthLoginResult {
        try await Task.sleep(for: .milliseconds(500))

        return .existingMember(
            tokenPair: TokenPair(
                accessToken: "mock_access_token",
                refreshToken: "mock_refresh_token"
            )
        )
    }

    func loginApple(
        authorizationCode: String
    ) async throws -> OAuthLoginResult {
        try await Task.sleep(for: .milliseconds(500))

        // Apple 로그인은 서버 미구현 → 에러 반환
        throw RepositoryError.serverError(
            code: "501",
            message: "Apple 로그인은 아직 지원되지 않습니다."
        )
    }

    func renewToken(
        refreshToken: String
    ) async throws -> TokenPair {
        try await Task.sleep(for: .milliseconds(300))

        return TokenPair(
            accessToken: "mock_new_access_token",
            refreshToken: "mock_new_refresh_token"
        )
    }

    func getMyOAuth() async throws -> [MemberOAuth] {
        try await Task.sleep(for: .milliseconds(300))

        return [
            MemberOAuth(
                memberOAuthId: 1,
                memberId: 102,
                provider: "KAKAO"
            )
        ]
    }

    func sendEmailVerification(
        email: String
    ) async throws -> String {
        try await Task.sleep(for: .milliseconds(500))
        return "mock_verification_id_1"
    }

    func verifyEmailCode(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        try await Task.sleep(for: .milliseconds(500))
        return "mock_email_verification_token"
    }

    func register(
        request: RegisterRequestDTO
    ) async throws -> Int {
        try await Task.sleep(for: .milliseconds(500))
        return 1
    }

    func getSchools() async throws -> [School] {
        try await Task.sleep(for: .milliseconds(300))
        return [
            School(id: "1", name: "중앙대학교"),
            School(id: "2", name: "서울대학교"),
            School(id: "3", name: "연세대학교")
        ]
    }

    func getTerms(
        termsType: String
    ) async throws -> Terms {
        try await Task.sleep(for: .milliseconds(300))
        let type = TermsType(rawValue: termsType) ?? .service
        return Terms(
            id: 1,
            title: "Mock 약관",
            content: "<p>Mock 약관 내용</p>",
            isMandatory: true,
            termsType: type
        )
    }
}
