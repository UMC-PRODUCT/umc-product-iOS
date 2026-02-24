//
//  OperatorAttendanceUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Implementation

/// 운영진 출석 관리 UseCase 구현체
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

    func updateScheduleLocation(
        scheduleId: Int,
        locationName: String,
        latitude: Double,
        longitude: Double
    ) async throws {
        try await repository.updateScheduleLocation(
            scheduleId: scheduleId,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude
        )
    }
}
