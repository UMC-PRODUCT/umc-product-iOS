//
//  ChallengerPointCreateRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 챌린저 포인트 부여 요청 DTO
///
/// `POST /api/v1/challenger/{challengerId}/points`
struct ChallengerPointCreateRequestDTO: Codable, Sendable {
    let pointType: ChallengerPointType
    let description: String
}

/// 챌린저 포인트 유형
enum ChallengerPointType: String, Codable, Sendable {
    case bestWorkbook = "BEST_WORKBOOK"
    case warning = "WARNING"
    case out = "OUT"
}
