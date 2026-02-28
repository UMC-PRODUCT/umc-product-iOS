//
//  OAuthLoginResponseDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// OAuth 로그인 API 응답 DTO
///
/// 서버 응답 result 구조:
/// - 기존 회원: accessToken + refreshToken 반환
/// - 신규 회원: oAuthVerificationToken만 반환
struct OAuthLoginResponseDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    /// JWT 액세스 토큰 (기존 회원만)
    let accessToken: String?
    /// JWT 리프레시 토큰 (기존 회원만)
    let refreshToken: String?
    /// OAuth 인증 토큰 (신규 회원만 - 회원가입 플로우용)
    let oAuthVerificationToken: String?

    // MARK: - Mapping

    /// Domain 모델로 변환
    func toDomain() -> OAuthLoginResult {
        if let accessToken, let refreshToken {
            return .existingMember(
                tokenPair: TokenPair(
                    accessToken: accessToken,
                    refreshToken: refreshToken
                )
            )
        } else if let oAuthVerificationToken {
            return .newMember(
                verificationToken: oAuthVerificationToken
            )
        } else {
            return .newMember(verificationToken: "")
        }
    }
}
