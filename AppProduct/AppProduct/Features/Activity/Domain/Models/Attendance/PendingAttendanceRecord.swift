//
//  PendingAttendanceRecord.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 승인 대기 출석 항목 Domain 모델
///
/// `GET /api/v1/attendances/pending/{scheduleId}` 응답 매핑
struct PendingAttendanceRecord: Equatable, Identifiable {
    let id: UUID = .init()
    let attendanceId: Int
    let memberId: Int
    let memberName: String
    let nickname: String
    let profileImageLink: URL?
    let schoolName: String
    let status: AttendanceStatus
    let reason: String?
    let requestedAt: Date
}
