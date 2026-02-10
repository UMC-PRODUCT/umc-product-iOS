//
//  CurriculumResponseDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Curriculum

/// 파트별 커리큘럼 조회 응답 DTO
///
/// `GET /api/v1/curriculums` 응답
///
/// - Note: `APIResponse<CurriculumResponseDTO>`로 디코딩
struct CurriculumResponseDTO: Codable {
    /// 커리큘럼 ID
    let id: Int
    /// 소속 파트
    let part: String
    /// 커리큘럼 제목 (예: "9기 Springboot")
    let title: String
    /// 워크북 목록
    let workbooks: [WorkbookDTO]
}

// MARK: - Workbook

/// 워크북 DTO
struct WorkbookDTO: Codable {
    /// 워크북 ID
    let id: Int
    /// 주차 번호
    let weekNo: Int
    /// 워크북 제목
    let title: String
    /// 워크북 설명
    let description: String
    /// 워크북 URL
    let workbookUrl: String
    /// 시작일
    let startDate: String
    /// 종료일
    let endDate: String
    /// 미션 타입 (LINK 등)
    let missionType: String
    /// 배포 일시
    let releasedAt: String
    /// 배포 여부
    let isReleased: Bool
}

// MARK: - Weeks

/// 파트별 커리큘럼 주차 목록 응답 DTO
///
/// `GET /api/v1/curriculums/weeks` 응답
///
/// - Note: `APIResponse<CurriculumWeeksResponseDTO>`로 디코딩
struct CurriculumWeeksResponseDTO: Codable {
    /// 주차 목록
    let weeks: [WeekItemDTO]
}

/// 주차 항목 DTO
struct WeekItemDTO: Codable {
    /// 주차 번호
    let weekNo: Int
    /// 주차 제목
    let title: String
}

// MARK: - Study Group

/// 필터용 스터디 그룹 항목 DTO
///
/// `GET /api/v1/curriculums/study-groups` 응답
///
/// - Note: `APIResponse<[StudyGroupDTO]>`로 디코딩 (배열)
struct StudyGroupDTO: Codable {
    /// 스터디 그룹 ID
    let groupId: Int
    /// 스터디 그룹 이름
    let name: String
}
