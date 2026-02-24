//
//  OperatorAttendanceRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

// MARK: - Protocol

/// 운영진 출석 관리 데이터 접근 Repository
protocol OperatorAttendanceRepositoryProtocol {

    // MARK: - 조회

    /// 승인 대기 출석 목록 조회 (관리자)
    func getPendingAttendances(
        scheduleId: Int
    ) async throws -> [PendingAttendanceRecord]

    /// 챌린저 출석 이력 조회
    func getChallengerHistory(
        challengerId: Int
    ) async throws -> [AttendanceHistoryItem]

    // MARK: - 액션

    /// 출석 승인 (관리자)
    func approveAttendance(recordId: Int) async throws

    /// 출석 반려 (관리자)
    func rejectAttendance(recordId: Int) async throws

    /// 세션 출석 위치 변경 (관리자)
    func updateScheduleLocation(
        scheduleId: Int,
        locationName: String,
        latitude: Double,
        longitude: Double
    ) async throws
}
