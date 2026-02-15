//
//  RegisterExistingChallengerRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 기존 챌린저 인증 코드 등록 요청 DTO
struct RegisterExistingChallengerRequestDTO: Codable {
    let code: String
}
