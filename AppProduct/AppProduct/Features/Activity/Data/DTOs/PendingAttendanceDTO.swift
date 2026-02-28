//
//  PendingAttendanceDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 승인 대기 출석 목록 Response DTO
///
/// `GET /api/v1/attendances/pending/{scheduleId}`
/// - Note: 서버는 모든 숫자를 String으로 반환
struct PendingAttendanceDTO: Codable, Sendable, Equatable {
    let attendanceId: String
    let memberId: String
    let memberName: String
    let nickname: String
    let profileImageLink: String?
    let schoolName: String
    let status: String
    let reason: String?
    let requestedAt: String
}

// MARK: - toDomain

extension PendingAttendanceDTO {

    /// DTO → PendingAttendanceRecord Domain 모델 변환
    func toDomain() -> PendingAttendanceRecord {
        PendingAttendanceRecord(
            attendanceId: Int(attendanceId) ?? 0,
            memberId: Int(memberId) ?? 0,
            memberName: memberName,
            nickname: nickname,
            profileImageLink: profileImageLink.flatMap {
                URL(string: $0)
            },
            schoolName: schoolName,
            status: AttendanceStatus(serverStatus: status),
            reason: reason,
            requestedAt: Self.parseISO8601(requestedAt)
        )
    }

    /// ISO 8601 문자열 → Date 변환
    private static func parseISO8601(_ string: String) -> Date {
        ServerDateTimeConverter.parseUTCDateTime(string)
            ?? .now
    }
}
