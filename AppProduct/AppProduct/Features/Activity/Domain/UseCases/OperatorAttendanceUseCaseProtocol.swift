//
//  OperatorAttendanceUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Protocol

protocol OperatorAttendanceUseCaseProtocol {
    /// 승인 대기 멤버 목록 조회
    func fetchPendingAttendances(scheduleId: Int) async throws -> [PendingAttendanceRecord]
    /// 전체 승인 대기 멤버 일괄 조회
    /// - Returns: scheduleId별로 그룹핑된 Dictionary
    func fetchAllPendingAttendances() async throws -> [Int: [PendingAttendanceRecord]]
    /// 개별 출석 승인
    func approveAttendance(recordId: Int) async throws
    /// 개별 출석 반려
    func rejectAttendance(recordId: Int) async throws

    /// 세션 출석 위치 변경
    func updateScheduleLocation(
        scheduleId: Int,
        locationName: String,
        latitude: Double,
        longitude: Double
    ) async throws

    /// 일정별 출석 통계 조회
    func fetchScheduleStats() async throws -> [ScheduleAttendanceStats]
}
