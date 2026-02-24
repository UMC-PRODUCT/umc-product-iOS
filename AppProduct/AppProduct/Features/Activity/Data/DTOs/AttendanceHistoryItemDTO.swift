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
        let startDate = Self.parseUTCDateTimeOrTime(
            startTime,
            utcDate: scheduledDate
        )
        let endDate = Self.parseUTCDateTimeOrTime(
            endTime,
            utcDate: scheduledDate
        )

        return AttendanceHistoryItem(
            attendanceId: Int(attendanceId) ?? 0,
            scheduleId: Int(scheduleId) ?? 0,
            scheduleName: scheduleName,
            tags: tag,
            scheduledDate: Self.toKSTDateString(
                startDate,
                fallback: scheduledDate
            ),
            startTime: Self.toKSTTimeString(
                startDate,
                fallback: startTime
            ),
            endTime: Self.toKSTTimeString(
                endDate,
                fallback: endTime
            ),
            status: AttendanceStatus(serverStatus: status),
            statusDisplay: statusDisplay
        )
    }

    // MARK: - Private Helper

    private static func parseUTCDateTimeOrTime(
        _ value: String,
        utcDate: String
    ) -> Date? {
        ServerDateTimeConverter.parseUTCDateTimeOrTime(
            value,
            utcDate: utcDate
        )
    }

    private static func toKSTDateString(
        _ date: Date?,
        fallback: String
    ) -> String {
        guard let date else { return fallback }
        return ServerDateTimeConverter.toKSTDateString(date)
    }

    private static func toKSTTimeString(
        _ date: Date?,
        fallback: String
    ) -> String {
        guard let date else { return fallback }
        return ServerDateTimeConverter.toKSTTimeString(date)
    }
}
