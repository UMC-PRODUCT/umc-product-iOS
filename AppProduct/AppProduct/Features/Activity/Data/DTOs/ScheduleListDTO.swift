//
//  ScheduleListDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 3/11/26.
//

import Foundation

/// 일정별 출석 통계 Response DTO
///
/// `GET /api/v1/schedules`
/// - Note: 서버는 모든 숫자를 String으로 반환
struct ScheduleListDTO: Codable, Sendable, Equatable {
    let scheduleId: String
    let name: String
    let status: String
    let date: String
    let startTime: String
    let endTime: String
    let locationName: String
    let sheetId: String
    let totalCount: String
    let presentCount: String
    let pendingCount: String
    let attendanceRate: String
}

// MARK: - toDomain

extension ScheduleListDTO {

    /// DTO → ScheduleAttendanceStats Domain 모델 변환
    ///
    /// - Note: 서버의 `attendanceRate`는 0-100 범위.
    ///   iOS View(Gauge)는 0-1 범위를 기대하므로 `/100.0` 변환.
    func toDomain() -> ScheduleAttendanceStats {
        ScheduleAttendanceStats(
            scheduleId: Int(scheduleId) ?? 0,
            totalCount: Int(totalCount) ?? 0,
            presentCount: Int(presentCount) ?? 0,
            pendingCount: Int(pendingCount) ?? 0,
            attendanceRate: (Double(attendanceRate) ?? 0.0)
                / 100.0
        )
    }
}
