//
//  AttendanceRecord.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 기록 상세 Domain 모델
///
/// `GET /api/v1/attendances/{recordId}` 응답 매핑
struct AttendanceRecord: Equatable, Identifiable {
    let id: Int
    let attendanceSheetId: Int
    let memberId: Int
    let status: AttendanceStatus
    let memo: String?
}
