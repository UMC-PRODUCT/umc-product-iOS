//
//  OAuthLoginResponseDTO.swift
//  AuthData
//
//  Created by euijjang97 on 7/9/26.
//

import CoreNetwork
import Foundation

/// OAuth 소셜 로그인 API 응답 DTO
///
/// 서버 응답 result 구조:
/// - 기존 회원: `accessToken` + `refreshToken` 반환
/// - 신규 회원: `oAuthVerificationToken`만 반환
///
public struct OAuthLoginResponseDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    public let success: Bool?
    public let code: String?
    /// JWT 액세스 토큰 (기존 회원만)
    public let accessToken: String?
    /// JWT 리프레시 토큰 (기존 회원만)
    public let refreshToken: String?
    /// OAuth 인증 토큰 (신규 회원만 - 회원가입 플로우용)
    public let oAuthVerificationToken: String?

    private enum CodingKeys: String, CodingKey {
        case success, code, accessToken, refreshToken, oAuthVerificationToken
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        oAuthVerificationToken = try container.decodeIfPresent(
            String.self, forKey: .oAuthVerificationToken
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(success, forKey: .success)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(oAuthVerificationToken, forKey: .oAuthVerificationToken)
    }
}

// MARK: - Mapping

extension OAuthLoginResponseDTO {
    /// 기존 회원 로그인 성공 시 발급된 토큰 쌍. 신규 회원인 경우 `nil`.
    var tokenPair: TokenPair? {
        guard let accessToken, let refreshToken,
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return TokenPair(accessToken: accessToken, refreshToken: refreshToken)
    }
}
