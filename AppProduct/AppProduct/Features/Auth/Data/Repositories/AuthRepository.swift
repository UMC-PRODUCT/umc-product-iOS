//
//  AuthRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation
import Moya

/// Auth Repository 구현체
///
/// - 인증 불요 API (login, renewToken): MoyaNetworkAdapter.requestWithoutAuth
/// - 인증 필요 API (getMyOAuth): MoyaNetworkAdapter.request
final class AuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function

    /// 카카오 소셜 로그인을 수행합니다.
    ///
    /// - Parameters:
    ///   - accessToken: 카카오 SDK에서 발급받은 액세스 토큰
    ///   - email: 카카오 계정 이메일
    /// - Returns: 기존 회원/신규 회원 분기 결과
    func loginKakao(
        accessToken: String,
        email: String
    ) async throws -> OAuthLoginResult {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.loginKakao(accessToken: accessToken, email: email)
        )
        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("[Auth] 카카오 로그인 응답: \(json)")
        }
        #endif
        let apiResponse = try decoder.decode(
            APIResponse<OAuthLoginResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }

    /// Apple 소셜 로그인을 수행합니다.
    ///
    /// - Parameter authorizationCode: Apple Sign In에서 발급받은 인증 코드
    /// - Returns: 기존 회원/신규 회원 분기 결과
    func loginApple(
        authorizationCode: String
    ) async throws -> OAuthLoginResult {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.loginApple(authorizationCode: authorizationCode)
        )
        #if DEBUG
        if let json = String(data: response.data, encoding: .utf8) {
            print("[Auth] 애플 로그인 응답: \(json)")
        }
        #endif
        let apiResponse = try decoder.decode(
            APIResponse<OAuthLoginResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }

    /// 리프레시 토큰으로 새 토큰 쌍을 발급받습니다.
    func renewToken(
        refreshToken: String
    ) async throws -> TokenPair {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.renewToken(refreshToken: refreshToken)
        )
        let apiResponse = try decoder.decode(
            APIResponse<TokenRenewResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }

    /// 내 OAuth 연동 정보 목록을 조회합니다.
    func getMyOAuth() async throws -> [MemberOAuth] {
        let response = try await adapter.request(AuthRouter.getMyOAuth)
        let apiResponse = try decoder.decode(
            APIResponse<[MemberOAuthDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    /// OAuth 수단을 추가 연동하고 갱신된 전체 연동 목록을 반환합니다.
    ///
    /// - Parameter oAuthVerificationToken: 소셜 로그인으로 발급받은 검증 토큰
    /// - Returns: 연동 완료 후 전체 OAuth 목록
    func addMemberOAuth(
        oAuthVerificationToken: String
    ) async throws -> [MemberOAuth] {
        let response = try await adapter.request(
            AuthRouter.addMemberOAuth(
                oAuthVerificationToken: oAuthVerificationToken
            )
        )
        let apiResponse = try decoder.decode(
            APIResponse<[MemberOAuthDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    /// 이메일 인증 코드를 발송합니다.
    ///
    /// - Parameter email: 인증할 이메일 주소
    /// - Returns: 발급된 이메일 인증 ID
    func sendEmailVerification(
        email: String
    ) async throws -> String {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.sendEmailVerification(email: email)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmailVerificationResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().emailVerificationId
    }

    /// 이메일 인증 코드를 검증합니다.
    ///
    /// - Parameters:
    ///   - emailVerificationId: 이메일 인증 ID
    ///   - verificationCode: 사용자가 입력한 인증 코드
    /// - Returns: 이메일 인증 토큰
    func verifyEmailCode(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.verifyEmailCode(
                emailVerificationId: emailVerificationId,
                verificationCode: verificationCode
            )
        )
        let apiResponse = try decoder.decode(
            APIResponse<VerifyEmailCodeResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().emailVerificationToken
    }

    /// 회원가입을 수행합니다.
    ///
    /// - Parameter request: 회원가입 요청 DTO
    /// - Returns: 생성된 회원 ID
    /// - Throws: `RepositoryError.decodingError` memberId 변환 실패 시
    func register(
        request: RegisterRequestDTO
    ) async throws -> Int {
        do {
            let response = try await adapter.requestWithoutAuth(
                AuthRouter.register(body: request)
            )
            let apiResponse = try decoder.decode(
                APIResponse<RegisterResponseDTO>.self,
                from: response.data
            )
            let dto = try apiResponse.unwrap()
            // 서버에서 memberId를 String으로 넘겨줌에 따른 타입 변환
            guard let id = Int(dto.memberId) else {
                throw RepositoryError.decodingError(
                    detail: "memberId 변환 실패: \(dto.memberId)"
                )
            }
            return id
        } catch let NetworkError.requestFailed(statusCode, data) {
            #if DEBUG
            if let data,
               let json = String(data: data, encoding: .utf8) {
                print("[Auth] register 에러 응답(\(statusCode)): \(json)")
            }
            #endif
            throw NetworkError.requestFailed(
                statusCode: statusCode,
                data: data
            )
        }
    }

    /// 기존 챌린저 코드로 인증합니다.
    func registerExistingChallenger(
        code: String
    ) async throws {
        _ = try await adapter.request(
            AuthRouter.registerExistingChallenger(code: code)
        )
    }

    /// 학교 목록을 조회합니다.
    func getSchools() async throws -> [School] {
        let response = try await adapter.requestWithoutAuth(
            AuthRouter.getSchools
        )
        let apiResponse = try decoder.decode(
            APIResponse<SchoolListResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().schools.map { $0.toDomain() }
    }

    /// 약관 정보를 조회합니다.
    ///
    /// - Parameter termsType: 약관 종류 (SERVICE, PRIVACY)
    /// - Returns: 약관 정보
    func getTerms(
        termsType: String
    ) async throws -> Terms {
        guard let type = TermsType(rawValue: termsType) else {
            throw RepositoryError.decodingError(
                detail: "Unknown termsType: \(termsType)"
            )
        }

        let response = try await adapter.requestWithoutAuth(
            AuthRouter.getTerms(termsType: termsType)
        )

        do {
            let apiResponse = try decoder.decode(
                APIResponse<TermsDTO>.self,
                from: response.data
            )
            return try apiResponse.unwrap().toDomain(termsType: type)
        } catch let decodingError as DecodingError {
            let rawResponse = String(
                data: response.data,
                encoding: .utf8
            ) ?? "<non-utf8 response>"
            throw RepositoryError.decodingError(
                detail: """
                getTerms(\(termsType)) decoding failed
                - reason: \(describeDecodingError(decodingError))
                - response: \(rawResponse)
                """
            )
        }
    }
}

// MARK: - Private Helpers

private extension AuthRepository {
    func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            let location = path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            return "Missing key: \(location)"
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Type mismatch: expected \(type) at \(path)"
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Value not found: \(type) at \(path)"
        case .dataCorrupted(let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Data corrupted at \(path): \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error"
        }
    }
}
