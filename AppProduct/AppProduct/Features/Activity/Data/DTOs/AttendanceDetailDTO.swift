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
struct AttendanceDetailDTO: Codable, Sendable, Equatable {
    let id: Int
    let attendanceSheetId: Int
    let memberId: Int
    let status: String
    let memo: String?
}

// MARK: - toDomain

extension AttendanceDetailDTO {

    /// DTO → AttendanceRecord Domain 모델 변환
    func toDomain() -> AttendanceRecord {
        AttendanceRecord(
            id: id,
            attendanceSheetId: attendanceSheetId,
            memberId: memberId,
            status: AttendanceStatus(serverStatus: status),
            memo: memo
        )
    }
}
