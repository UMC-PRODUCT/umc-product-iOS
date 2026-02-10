
//
//  CurriculumWorkbookRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Workbook Submission Query

/// 워크북 제출 현황 조회 쿼리 DTO
///
/// `GET /api/v1/curriculums/workbook-submissions` 쿼리 파라미터
struct WorkbookSubmissionQuery: Encodable {
    let week: Int
    let part: String
    let schoolId: Int
    let page: Int
    let size: Int
    
    var toParameters: [String: Any] {
        [
            "week": week,
            "part": part,
            "schoolId": schoolId,
            "page": page,
            "size": size
        ]
    }
}

// MARK: - Submit Workbook Request

/// 워크북 제출 요청 DTO
///
/// `POST /api/v1/challenger-workbooks/{challengerWorkbookId}/submissions` 요청 Body
struct SubmitWorkbookRequestDTO: Encodable {
    /// 제출 링크 (깃허브, 노션 등)
    let submission: String
}
