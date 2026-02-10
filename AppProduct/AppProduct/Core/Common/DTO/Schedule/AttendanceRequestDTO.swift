
//
//  AttendanceRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Submit Attendance Reason

/// 출석 사유 제출 요청 DTO
///
/// `POST /api/v1/attendances/reason` 요청 Body
struct SubmitAttendanceReasonRequestDTO: Encodable {
    let attendanceSheetId: Int
    let reason: String
}

// MARK: - Check Attendance

/// 출석 체크 요청 DTO
///
/// `POST /api/v1/attendances/check` 요청 Body
struct CheckAttendanceRequestDTO: Encodable {
    let attendanceSheetId: Int
    let latitude: Double
    let longitude: Double
    let locationVerified: Bool
}
