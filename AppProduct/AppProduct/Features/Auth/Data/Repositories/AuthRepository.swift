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

    func loginKakao(
        accessToken: String,
        email: String
    ) async throws -> OAuthLoginResult {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.loginKakao(accessToken: accessToken, email: email)
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

    func loginApple(
        authorizationCode: String
    ) async throws -> OAuthLoginResult {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.loginApple(authorizationCode: authorizationCode)
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

    func renewToken(
        refreshToken: String
    ) async throws -> TokenPair {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.renewToken(refreshToken: refreshToken)
        )
        let apiResponse = try decoder.decode(
            APIResponse<TokenRenewResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }

    func getMyOAuth() async throws -> [MemberOAuth] {
        let response = try await adapter.request(AuthAPI.getMyOAuth)
        let apiResponse = try decoder.decode(
            APIResponse<[MemberOAuthDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    func sendEmailVerification(
        email: String
    ) async throws -> String {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.sendEmailVerification(email: email)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmailVerificationResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().emailVerificationId
    }

    func verifyEmailCode(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.verifyEmailCode(
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

    func register(
        request: RegisterRequestDTO
    ) async throws -> Int {
        do {
            let response = try await adapter.requestWithoutAuth(
                AuthAPI.register(body: request)
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

    func getSchools() async throws -> [School] {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.getSchools
        )
        let apiResponse = try decoder.decode(
            APIResponse<SchoolListResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().schools.map { $0.toDomain() }
    }

    func getTerms(
        termsType: String
    ) async throws -> Terms {
        let response = try await adapter.requestWithoutAuth(
            AuthAPI.getTerms(termsType: termsType)
        )
        let apiResponse = try decoder.decode(
            APIResponse<TermsDTO>.self,
            from: response.data
        )
        guard let type = TermsType(rawValue: termsType) else {
            throw RepositoryError.decodingError(
                detail: "Unknown termsType: \(termsType)"
            )
        }
        return try apiResponse.unwrap().toDomain(termsType: type)
    }
}
