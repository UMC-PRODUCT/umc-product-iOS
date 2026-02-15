//
//  MemberOAuthDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// 회원 OAuth 연동 정보 API 응답 DTO
struct MemberOAuthDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    /// OAuth 연동 ID
    let memberOAuthId: Int
    /// 회원 ID
    let memberId: Int
    /// OAuth 제공자 (KAKAO, APPLE)
    let provider: OAuthProvider

    // MARK: - Mapping

    /// Domain 모델로 변환
    func toDomain() -> MemberOAuth {
        MemberOAuth(
            memberOAuthId: memberOAuthId,
            memberId: memberId,
            provider: provider
        )
    }
}
