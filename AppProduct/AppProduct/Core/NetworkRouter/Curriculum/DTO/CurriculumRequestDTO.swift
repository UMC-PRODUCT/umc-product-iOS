//
//  CurriculumRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Submit Workbook

/// 워크북 제출 요청 DTO
///
/// `POST /api/v1/challenger-workbooks/{challengerWorkbookId}/submissions` 요청 Body
///
/// - Important: PENDING 상태의 워크북만 제출 가능. 한 번 제출하면 수정 불가.
struct SubmitWorkbookRequestDTO: Encodable {
    /// 제출 링크 (깃허브, 노션 등)
    let submission: String
}
