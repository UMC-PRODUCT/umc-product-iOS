//
//  EmailVerificationResponseDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 이메일 인증 발송 API 응답 DTO
struct EmailVerificationResponseDTO: Codable {

    // MARK: - Property

    /// 이메일 인증 ID (서버가 String 반환: "51")
    let emailVerificationId: String
}
