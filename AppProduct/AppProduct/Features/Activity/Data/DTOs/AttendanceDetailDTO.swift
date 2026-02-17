//
//  AttendanceDetailDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 기록 상세 Response DTO
///
/// `GET /api/v1/attendances/{recordId}`
/// - Note: 서버는 모든 숫자를 String으로 반환
struct AttendanceDetailDTO: Codable, Sendable, Equatable {
    let id: String
    let attendanceSheetId: String
    let memberId: String
    let status: String
    let memo: String?
}

// MARK: - toDomain

extension AttendanceDetailDTO {

    /// DTO → AttendanceRecord Domain 모델 변환
    func toDomain() -> AttendanceRecord {
        AttendanceRecord(
            id: Int(id) ?? 0,
            attendanceSheetId: Int(attendanceSheetId) ?? 0,
            memberId: Int(memberId) ?? 0,
            status: AttendanceStatus(serverStatus: status),
            memo: memo
        )
    }
}
