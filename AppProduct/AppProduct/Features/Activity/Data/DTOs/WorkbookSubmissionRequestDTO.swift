//
//  WorkbookSubmissionRequestDTO.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation

/// 워크북 제출 요청 DTO
///
/// `POST /api/v1/challenger-workbooks/{challengerWorkbookId}/submissions`
struct WorkbookSubmissionRequestDTO: Encodable, Sendable, Equatable {
    let submission: String
}
