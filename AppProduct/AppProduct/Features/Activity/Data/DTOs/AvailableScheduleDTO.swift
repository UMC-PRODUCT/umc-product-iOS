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
/// - Note: 서버는 모든 숫자를 String으로 반환
struct AvailableScheduleDTO: Codable, Sendable, Equatable {
    let scheduleId: String
    let scheduleName: String
    let tags: [String]
    let startTime: String
    let endTime: String
    let sheetId: String
    let recordId: String?
    let status: String
    let statusDisplay: String
    let locationVerified: Bool?
}

// MARK: - toDomain

extension AvailableScheduleDTO {

    /// DTO → AvailableAttendanceSchedule Domain 모델 변환
    func toDomain() -> AvailableAttendanceSchedule {
        AvailableAttendanceSchedule(
            scheduleId: Int(scheduleId) ?? 0,
            scheduleName: scheduleName,
            tags: tags,
            startTime: startTime,
            endTime: endTime,
            sheetId: Int(sheetId) ?? 0,
            recordId: recordId.flatMap { Int($0) },
            status: AttendanceStatus(serverStatus: status),
            statusDisplay: statusDisplay,
            locationVerified: locationVerified ?? false
        )
    }
}
