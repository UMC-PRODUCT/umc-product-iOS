//
//  WorkbookSubmissionDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Query

/// 워크북 제출 현황 조회 쿼리
///
/// `GET /api/v1/curriculums/workbook-submissions` 쿼리 파라미터
///
/// - Important: 학교 운영진(회장/부회장/파트장/기타 운영진)만 접근 가능
struct WorkbookSubmissionQuery {
    /// 주차 (필수)
    let weekNo: Int
    /// 스터디 그룹 ID (선택)
    var studyGroupId: Int? = nil
    /// 페이지 커서 (첫 페이지는 nil)
    var cursor: Int? = nil
    /// 페이지 크기 (기본 20, 최대 100)
    var size: Int = 20

    // MARK: - Function

    /// 쿼리 파라미터 딕셔너리를 반환
    var toParameters: [String: Any] {
        var params: [String: Any] = ["weekNo": weekNo, "size": size]
        if let studyGroupId { params["studyGroupId"] = studyGroupId }
        if let cursor { params["cursor"] = cursor }
        return params
    }
}

// MARK: - Response

/// 워크북 제출 현황 항목 DTO
struct WorkbookSubmissionItemDTO: Codable {
    /// 챌린저 워크북 ID
    let challengerWorkbookId: Int
    /// 챌린저 ID
    let challengerId: Int
    /// 챌린저 이름
    let challengerName: String
    /// 프로필 이미지 URL
    let profileImageUrl: String?
    /// 학교명
    let schoolName: String
    /// 소속 파트
    let part: String
    /// 워크북 제목
    let workbookTitle: String
    /// 제출 상태 (SUBMITTED 등)
    let status: String
}
