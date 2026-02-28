//
//  AttendanceReasonRequestDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 사유 제출 출석 요청 DTO
///
/// `POST /api/v1/attendances/reason`
struct AttendanceReasonRequestDTO: Encodable, Sendable {
    /// 출석 시트 ID
    let attendanceSheetId: Int
    /// 사유 내용
    let reason: String
}
