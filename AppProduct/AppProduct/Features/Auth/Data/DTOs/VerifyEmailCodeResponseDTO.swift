//
//  VerifyEmailCodeResponseDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 이메일 인증코드 검증 API 응답 DTO
struct VerifyEmailCodeResponseDTO: Codable {

    // MARK: - Property

    /// 이메일 인증 토큰 (회원가입 시 사용)
    let emailVerificationToken: String
}
