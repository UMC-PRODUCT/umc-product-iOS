//
//  FetchScheduleDetailUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 일정 상세 조회 UseCase Protocol
protocol FetchScheduleDetailUseCaseProtocol {
    /// 일정 상세 조회
    /// - Parameter scheduleId: 일정 ID
    /// - Returns: 일정 상세 데이터
    func execute(scheduleId: Int) async throws -> ScheduleDetailData
}
