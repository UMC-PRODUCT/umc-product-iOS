//
//  AvailableAttendanceSchedule.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 가능 일정 Domain 모델
///
/// `GET /api/v1/attendances/available` 응답 매핑
struct AvailableAttendanceSchedule: Equatable, Identifiable {
    let id: UUID = .init()
    let scheduleId: Int
    let scheduleName: String
    let tags: [String]
    let startTime: String
    let endTime: String
    let sheetId: Int
    let recordId: Int
    let status: AttendanceStatus
    let statusDisplay: String
    let locationVerified: Bool
}
