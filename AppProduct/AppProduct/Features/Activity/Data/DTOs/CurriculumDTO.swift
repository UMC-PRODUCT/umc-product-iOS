//
//  CurriculumDTO.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation

/// 파트별 커리큘럼 조회 응답 DTO
///
/// `GET /api/v1/curriculums?part={PART}`
struct CurriculumDTO: Codable, Sendable, Equatable {
    let id: String
    let part: String
    let title: String
    let workbooks: [CurriculumWorkbookDTO]
}

struct CurriculumWorkbookDTO: Codable, Sendable, Equatable {
    let id: String
    let weekNo: String
    let title: String
    let description: String
    let workbookUrl: String?
    let startDate: String
    let endDate: String
    let missionType: String
    let releasedAt: String?
    let isReleased: Bool
}

// MARK: - Helper

extension CurriculumDTO {
    /// 주차 번호 기준 스케줄 맵
    var scheduleByWeek: [Int: WorkbookSchedule] {
        Dictionary(
            uniqueKeysWithValues: workbooks.compactMap { workbook in
                guard let week = Int(workbook.weekNo) else { return nil }
                return (week, WorkbookSchedule(
                    startDate: workbook.startDate.asISO8601Date,
                    endDate: workbook.endDate.asISO8601Date
                ))
            }
        )
    }
}

struct WorkbookSchedule: Sendable, Equatable {
    let startDate: Date?
    let endDate: Date?
}

private extension String {
    var asISO8601Date: Date? {
        ISO8601DateFormatter.full.date(from: self)
        ?? ISO8601DateFormatter.basic.date(from: self)
    }
}

private extension ISO8601DateFormatter {
    static let full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
