//
//  AddMemberOAuthRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 로그인 OAuth 수단 추가 연동 요청 DTO
struct AddMemberOAuthRequestDTO: Codable, Sendable, Equatable {
    /// 소셜 로그인 시 발급받은 OAuth 검증 토큰
    let oAuthVerificationToken: String
}
