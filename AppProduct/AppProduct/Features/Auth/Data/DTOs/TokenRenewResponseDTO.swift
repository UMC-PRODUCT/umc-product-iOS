//
//  TokenRenewResponseDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// 토큰 재발급 API 응답 DTO
struct TokenRenewResponseDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    /// 새로 발급된 액세스 토큰
    let accessToken: String
    /// 새로 발급된 리프레시 토큰
    let refreshToken: String

    // MARK: - Mapping

    /// Domain 모델(TokenPair)로 변환
    func toDomain() -> TokenPair {
        TokenPair(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
