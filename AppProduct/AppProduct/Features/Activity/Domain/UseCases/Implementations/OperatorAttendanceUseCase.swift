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
    ///
    /// - Note: 다음 단계에서 OperatorAttendanceUseCaseProtocol 리팩토링 시
    ///   반환 타입을 `[PendingAttendanceRecord]`로 변경 예정
    func fetchPendingAttendances(sessionId: SessionID) async throws -> [Attendance] {
        // TODO: 다음 단계에서 Protocol 리팩토링 시 구현
        return []
    }

    /// 개별 출석 승인
    func approveAttendance(attendanceId: AttendanceID) async throws -> Attendance {
        // TODO: 다음 단계에서 Protocol 리팩토링 시 구현
        // try await repository.approveAttendance(recordId: Int(attendanceId.value) ?? 0)
        throw RepositoryError.serverError(
            code: "NOT_IMPLEMENTED",
            message: "다음 단계에서 구현 예정"
        )
    }

    /// 전체 일괄 승인
    func approveAllAttendances(sessionId: SessionID) async throws -> [Attendance] {
        // TODO: 다음 단계에서 Protocol 리팩토링 시 구현
        return []
    }

    /// 출석 거부
    func rejectAttendance(attendanceId: AttendanceID, reason: String) async throws -> Attendance {
        // TODO: 다음 단계에서 Protocol 리팩토링 시 구현
        throw RepositoryError.serverError(
            code: "NOT_IMPLEMENTED",
            message: "다음 단계에서 구현 예정"
        )
    }

    /// 세션별 전체 출석 현황 조회
    func fetchSessionAttendances(sessionId: SessionID) async throws -> [Attendance] {
        // TODO: 다음 단계에서 Protocol 리팩토링 시 구현
        return []
    }
}
