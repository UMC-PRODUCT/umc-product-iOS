//
//  AvailableScheduleDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 가능 일정 Response DTO
///
/// `GET /api/v1/attendances/available`
struct AvailableScheduleDTO: Codable, Sendable, Equatable {
    let scheduleId: Int
    let scheduleName: String
    let tags: [String]
    let startTime: String
    let endTime: String
    let sheetId: Int
    let recordId: Int
    let status: String
    let statusDisplay: String
    let locationVerified: Bool
}

// MARK: - toDomain

extension AvailableScheduleDTO {

    /// DTO → AvailableAttendanceSchedule Domain 모델 변환
    func toDomain() -> AvailableAttendanceSchedule {
        AvailableAttendanceSchedule(
            scheduleId: scheduleId,
            scheduleName: scheduleName,
            tags: tags,
            startTime: startTime,
            endTime: endTime,
            sheetId: sheetId,
            recordId: recordId,
            status: AttendanceStatus(serverStatus: status),
            statusDisplay: statusDisplay,
            locationVerified: locationVerified
        )
    }
}
