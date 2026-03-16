//
//  ScheduleAttendanceStats.swift
//  AppProduct
//
//  Created by jaewon Lee on 3/11/26.
//

import Foundation

/// 일정별 출석 통계
///
/// `GET /api/v1/schedules` 응답에서 출석 집계 필드만 추출한 모델.
/// `attendanceRate`는 0.0-1.0 범위 (DTO에서 변환 완료).
struct ScheduleAttendanceStats: Equatable, Sendable {
    let scheduleId: Int
    let name: String
    let date: String
    let startTime: String
    let endTime: String
    let locationName: String
    let totalCount: Int
    let presentCount: Int
    let pendingCount: Int
    let attendanceRate: Double
}
