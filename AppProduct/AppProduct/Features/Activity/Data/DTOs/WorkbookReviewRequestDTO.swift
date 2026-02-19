//
//  WorkbookReviewRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 챌린저 워크북 검토 요청 DTO
///
/// `POST /api/v1/workbooks/challenger/{challengerWorkbookId}/review`
struct WorkbookReviewRequestDTO: Codable, Sendable, Equatable {
    let status: String
    let feedback: String
}
