//
//  FetchSchedulesUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation

/// 월별 내 일정 조회 UseCase 구현
final class FetchSchedulesUseCase: FetchSchedulesUseCaseProtocol {
    private let repository: HomeRepositoryProtocol

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        year: Int, month: Int
    ) async throws -> [Date: [ScheduleData]] {
        try await repository.getSchedules(
            year: year, month: month
        )
    }
}
