//
//  WorkbookSubmissionRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 워크북 제출 요청 DTO
///
/// `POST /api/v1/challenger-workbooks/submissions`
struct WorkbookSubmissionRequestDTO: Encodable, Sendable, Equatable {
    let originalWorkbookId: Int
    let submission: String
}
