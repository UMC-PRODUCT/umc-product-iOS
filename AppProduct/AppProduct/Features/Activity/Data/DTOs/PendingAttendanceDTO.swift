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
struct PendingAttendanceDTO: Codable, Sendable, Equatable {
    let attendanceId: Int
    let memberId: Int
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
            attendanceId: attendanceId,
            memberId: memberId,
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
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return formatterWithFraction.date(from: string)
            ?? formatter.date(from: string)
            ?? .now
    }
}
