
//
//  CurriculumCommonRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Query

/// 파트별 커리큘럼 조회 쿼리 DTO
///
/// `GET /api/v1/curriculums` & `GET /api/v1/curriculums/weeks` 쿼리 파라미터
struct PartQuery: Encodable {
    /// 파트 (예: "IOS", "ANDROID", "SPRING", etc.)
    let part: String
    
    var toParameters: [String: Any] {
        ["part": part]
    }
}

/// 필터용 스터디 그룹 목록 조회 쿼리 DTO
///
/// `GET /api/v1/curriculums/study-groups` 쿼리 파라미터
struct StudyGroupFilterQuery: Encodable {
    /// 학교 ID
    let schoolId: Int
    /// 파트
    let part: String
    
    var toParameters: [String: Any] {
        ["schoolId": schoolId, "part": part]
    }
}
