//
//  AttendanceRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Protocol

protocol AttendanceRepositoryProtocol {
    /// 출석 요청 생성 (pending 상태)
    func createAttendance(request: CreateAttendanceRequest) async throws -> Attendance

    /// 출석 상태 업데이트 (승인/거부)
    func updateAttendanceStatus(
        attendanceId: AttendenceID,
        status: AttendenceStatus,
        verification: LocationVerification?
    ) async throws -> Attendance

    /// 세션별 승인 대기 출석 조회
    func fetchPendingAttendances(sessionId: SessionID) async throws -> [Attendance]

    /// 세션별 전체 출석 조회
    func fetchAttendances(sessionId: SessionID) async throws -> [Attendance]

    /// 사용자별 출석 히스토리 조회
    func fetchUserAttendanceHistory(userId: UserID) async throws -> [Attendance]
}

// MARK: - Request Model (DTO 나오기전 임시 작성)

struct CreateAttendanceRequest {
    let sessionId: SessionID
    let userId: UserID
    let type: AttendenceType
    let coordinate: Coordinate?
    let reason: String?
}
