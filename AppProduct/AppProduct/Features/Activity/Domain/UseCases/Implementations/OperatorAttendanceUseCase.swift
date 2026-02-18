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

    private let repository: OperatorAttendanceRepositoryProtocol

    // MARK: - Init

    init(repository: OperatorAttendanceRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func fetchPendingAttendances(scheduleId: Int) async throws -> [PendingAttendanceRecord] {
        try await repository.getPendingAttendances(scheduleId: scheduleId)
    }

    func approveAttendance(recordId: Int) async throws {
        try await repository.approveAttendance(recordId: recordId)
    }

    func rejectAttendance(recordId: Int) async throws {
        try await repository.rejectAttendance(recordId: recordId)
    }
}
