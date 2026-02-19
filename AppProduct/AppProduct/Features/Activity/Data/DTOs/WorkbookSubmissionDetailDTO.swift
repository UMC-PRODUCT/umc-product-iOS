//
//  WorkbookSubmissionDetailDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 챌린저 워크북 제출 URL 조회 응답 DTO
///
/// `GET /api/v1/workbooks/challenger/{challengerWorkbookId}/submissions`
struct WorkbookSubmissionDetailDTO: Codable, Sendable, Equatable {
    let challengerWorkbookId: Int
    let submission: String?
}
