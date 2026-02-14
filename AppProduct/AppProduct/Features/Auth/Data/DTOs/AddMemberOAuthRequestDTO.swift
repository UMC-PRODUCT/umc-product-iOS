//
//  AddMemberOAuthRequestDTO.swift
//  AppProduct
//
//  Created by Codex on 2/15/26.
//

import Foundation

/// 로그인 OAuth 수단 추가 연동 요청 DTO
struct AddMemberOAuthRequestDTO: Codable, Sendable, Equatable {
    let oAuthVerificationToken: String
}
