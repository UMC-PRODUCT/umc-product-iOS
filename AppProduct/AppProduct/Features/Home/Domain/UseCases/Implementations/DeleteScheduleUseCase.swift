//
//  DeleteScheduleUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 일정 + 출석부 통합 삭제 UseCase 구현체
final class DeleteScheduleUseCase: DeleteScheduleUseCaseProtocol {

    // MARK: - Property

    private let repository: ScheduleRepositoryProtocol

    // MARK: - Init

    init(repository: ScheduleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// 일정과 연결된 출석부를 함께 삭제합니다.
    /// - Parameter scheduleId: 삭제할 일정 ID
    /// - Throws: 서버 에러 또는 네트워크 에러
    func execute(scheduleId: Int) async throws {
        try await repository.deleteScheduleWithAttendance(
            scheduleId: scheduleId
        )
    }
}
