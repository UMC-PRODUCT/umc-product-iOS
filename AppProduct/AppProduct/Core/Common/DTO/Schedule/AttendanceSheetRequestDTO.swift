
//
//  AttendanceSheetRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Update Attendance Sheet

/// 출석부 수정 요청 DTO
///
/// `PATCH /api/v1/schedules/attendance-sheets/{sheetId}` 요청 Body
struct UpdateAttendanceSheetRequestDTO: Encodable {
    let startTime: String
    let endTime: String
    let lateThresholdMinutes: Int
    let requiresApproval: Bool
}
