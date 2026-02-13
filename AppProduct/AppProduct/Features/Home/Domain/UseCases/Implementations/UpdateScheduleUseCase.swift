//
//  UpdateScheduleUseCase.swift
//  AppProduct
//
//  Created by Codex on 2/13/26.
//

import Foundation

/// 일정 수정 UseCase 구현체
final class UpdateScheduleUseCase: UpdateScheduleUseCaseProtocol {

    // MARK: - Property

    private let repository: ScheduleRepositoryProtocol

    // MARK: - Init

    init(repository: ScheduleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// 일정 정보를 수정합니다.
    /// - Parameters:
    ///   - scheduleId: 수정할 일정 ID
    ///   - schedule: 일정 수정 요청 DTO
    /// - Throws: 서버 에러 또는 네트워크 에러
    func execute(scheduleId: Int, schedule: UpdateScheduleRequestDTO) async throws {
        try await repository.updateSchedule(scheduleId: scheduleId, schedule: schedule)
    }
}
