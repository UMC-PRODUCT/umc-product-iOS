//
//  OperatorAttendanceUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Implementation

final class OperatorAttendanceUseCase: OperatorAttendanceUseCaseProtocol {

    // MARK: - Property

    private let repository: AttendanceRepositoryProtocol

    // MARK: - Init

    init(repository: AttendanceRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// 승인 대기 명단 조회
    func fetchPendingAttendances(sessionId: SessionID) async throws -> [Attendance] {
        try await repository.fetchPendingAttendances(sessionId: sessionId)
    }

    /// 개별 출석 승인
    func approveAttendance(attendanceId: AttendanceID) async throws -> Attendance {
        try await repository.updateAttendanceStatus(
            attendanceId: attendanceId,
            status: .present,
            verification: nil
        )
    }

    /// 전체 일괄 승인
    func approveAllAttendances(sessionId: SessionID) async throws -> [Attendance] {
        let pendingAttendances = try await fetchPendingAttendances(sessionId: sessionId)

        var approvedAttendances: [Attendance] = []
        for attendance in pendingAttendances {
            let approved = try await repository.updateAttendanceStatus(
                attendanceId: AttendanceID(value: attendance.id.uuidString),
                status: .present,
                verification: nil
            )
            approvedAttendances.append(approved)
        }

        return approvedAttendances
    }

    /// 출석 거부
    func rejectAttendance(attendanceId: AttendanceID, reason: String) async throws -> Attendance {
        try await repository.updateAttendanceStatus(
            attendanceId: attendanceId,
            status: .absent,
            verification: nil
        )
    }

    /// 세션별 전체 출석 현황 조회
    func fetchSessionAttendances(sessionId: SessionID) async throws -> [Attendance] {
        try await repository.fetchAttendances(sessionId: sessionId)
    }
}
