//
//  RegisterResponseDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 회원가입 API 응답 DTO
struct RegisterResponseDTO: Codable {

    // MARK: - Property

    /// 생성된 회원 ID (서버가 String 반환)
    let memberId: String
}
