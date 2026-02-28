//
//  ChallengerAttendanceRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

// MARK: - Protocol

/// 챌린저 출석 데이터 접근 Repository
protocol ChallengerAttendanceRepositoryProtocol {

    // MARK: - 조회

    /// 내 출석 이력 조회
    func getMyHistory() async throws -> [AttendanceHistoryItem]

    /// 출석 가능 일정 조회
    func getAvailableSchedules(
    ) async throws -> [AvailableAttendanceSchedule]

    // MARK: - 액션

    /// GPS 출석 체크
    func checkAttendance(
        request: AttendanceCheckRequestDTO
    ) async throws -> Int

    /// 사유 제출 출석
    func submitReason(
        request: AttendanceReasonRequestDTO
    ) async throws -> Int
}
