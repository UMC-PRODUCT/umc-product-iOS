//
//  ChallengerRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Create Point

/// 챌린저 상벌점 부여 요청 DTO
///
/// `POST /api/v1/challenger/{challengerId}/points` 요청 Body
struct CreateChallengerPointRequestDTO: Encodable {
    /// 포인트 타입 (BEST_WORKBOOK 등)
    let pointType: String
    /// 부여 사유
    let description: String
}

// MARK: - Update Point Reason

/// 챌린저 상벌점 사유 수정 요청 DTO
///
/// `PATCH /api/v1/challenger/points/{challengerPointId}` 요청 Body
struct UpdatePointReasonRequestDTO: Encodable {
    /// 변경할 사유
    let newDescription: String
}
