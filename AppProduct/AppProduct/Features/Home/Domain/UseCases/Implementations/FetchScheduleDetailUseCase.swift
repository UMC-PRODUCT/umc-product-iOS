//
//  FetchScheduleDetailUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 일정 상세 조회 UseCase 구현
final class FetchScheduleDetailUseCase: FetchScheduleDetailUseCaseProtocol {
    private let repository: HomeRepositoryProtocol

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(scheduleId: Int) async throws -> ScheduleDetailData {
        try await repository.getScheduleDetail(scheduleId: scheduleId)
    }
}
