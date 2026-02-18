//
//  AttendanceHistoryItemDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 이력 항목 Response DTO
///
/// `GET /api/v1/attendances/history` 및
/// `GET /api/v1/attendances/challenger/{challengerId}/history`
/// - Note: 서버는 모든 숫자를 String으로 반환
struct AttendanceHistoryItemDTO: Codable, Sendable, Equatable {
    let attendanceId: String
    let scheduleId: String
    let scheduleName: String
    let tag: [String]
    let scheduledDate: String
    let startTime: String
    let endTime: String
    let status: String
    let statusDisplay: String
}

// MARK: - toDomain

extension AttendanceHistoryItemDTO {

    /// DTO → AttendanceHistoryItem Domain 모델 변환
    func toDomain() -> AttendanceHistoryItem {
        AttendanceHistoryItem(
            attendanceId: Int(attendanceId) ?? 0,
            scheduleId: Int(scheduleId) ?? 0,
            scheduleName: scheduleName,
            tags: tag,
            scheduledDate: scheduledDate,
            startTime: startTime,
            endTime: endTime,
            status: AttendanceStatus(serverStatus: status),
            statusDisplay: statusDisplay
        )
    }
}
