//
//  AttendanceCheckRequestDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// GPS 출석 체크 요청 DTO
///
/// `POST /api/v1/attendances/check`
struct AttendanceCheckRequestDTO: Encodable, Sendable {
    /// 출석 시트 ID
    let attendanceSheetId: Int
    /// 위도
    let latitude: Double
    /// 경도
    let longitude: Double
    /// 위치 검증 여부
    let locationVerified: Bool
}
