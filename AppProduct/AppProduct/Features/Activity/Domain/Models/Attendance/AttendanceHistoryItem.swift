//
//  AttendanceHistoryItem.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 이력 항목 Domain 모델
///
/// `GET /api/v1/attendances/history` 및
/// `GET /api/v1/attendances/challenger/{challengerId}/history` 응답 매핑
struct AttendanceHistoryItem: Equatable, Identifiable {
    let id: UUID = .init()
    let attendanceId: Int
    let scheduleId: Int
    let scheduleName: String
    let tags: [String]
    let scheduledDate: String
    let startTime: String
    let endTime: String
    let status: AttendanceStatus
    let statusDisplay: String
}
