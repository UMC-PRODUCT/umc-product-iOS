//
//  CurriculumWeeksDTO.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation

/// 파트별 커리큘럼 주차 목록 응답 DTO
///
/// `GET /api/v1/curriculums/weeks?part={PART}`
struct CurriculumWeeksDTO: Codable, Sendable, Equatable {
    let weeks: [CurriculumWeekItemDTO]
}

struct CurriculumWeekItemDTO: Codable, Sendable, Equatable {
    let weekNo: String
    let title: String
}
