//
//  DeleteMemberOAuthRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 3/10/26.
//

import Foundation

/// 로그인 OAuth 수단 연동 해제 요청 DTO
struct DeleteMemberOAuthRequestDTO: Codable, Sendable, Equatable {
    /// Google 연동 해제 검증용 액세스 토큰
    let googleAccessToken: String?

    /// Kakao 연동 해제 검증용 액세스 토큰
    let kakaoAccessToken: String?
}
