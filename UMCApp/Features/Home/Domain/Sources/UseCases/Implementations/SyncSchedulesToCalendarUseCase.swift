//
//  SyncSchedulesToCalendarUseCase.swift
//  HomeDomain
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation

/// 구간 일정을 애플 캘린더로 내보내는 UseCase 구현체
public final class SyncSchedulesToCalendarUseCase: SyncSchedulesToCalendarUseCaseProtocol {

    // MARK: - Property

    private let repository: CalendarSyncRepositoryProtocol

    // MARK: - Init

    public init(repository: CalendarSyncRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// 참여하지 않는 일정까지 개인 캘린더에 넣으면 알림 소음이 되므로
    /// ``ScheduleDetailData/isParticipant`` 가 `true` 인 일정만 넘긴다.
    ///
    /// 연동 OFF 검사를 호출자에 맡기면 진입점마다 같은 가드가 늘어나므로 여기서 한 번만 한다.
    public func execute(from: Date, to: Date, schedules: [ScheduleDetailData]) async throws {
        guard repository.isSyncEnabled else { return }

        try await repository.reconcile(
            from: from,
            to: to,
            schedules: schedules.filter(\.isParticipant)
        )
    }
}
