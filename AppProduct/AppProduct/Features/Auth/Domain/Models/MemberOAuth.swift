//
//  MemberOAuth.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// 회원 OAuth 연동 정보
struct MemberOAuth: Equatable, Sendable {

    // MARK: - Property

    /// OAuth 연동 ID
    let memberOAuthId: Int
    /// 회원 ID
    let memberId: Int
    /// OAuth 제공자 (APPLE, KAKAO)
    let provider: OAuthProvider
}
