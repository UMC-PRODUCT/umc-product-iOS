//
//  SyncSchedulesToCalendarUseCaseProtocol.swift
//  HomeDomain
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation

/// 구간 일정을 애플 캘린더로 내보내는 UseCase 인터페이스
public protocol SyncSchedulesToCalendarUseCaseProtocol {

    /// 연동이 켜져 있으면 구간 일정 중 참여 일정만 전용 캘린더에 반영한다.
    ///
    /// - Parameters:
    ///   - from: 반영할 구간 시작 시각
    ///   - to: 반영할 구간 종료 시각
    ///   - schedules: 그 구간의 서버 일정 전체
    func execute(from: Date, to: Date, schedules: [ScheduleDetailData]) async throws
}
