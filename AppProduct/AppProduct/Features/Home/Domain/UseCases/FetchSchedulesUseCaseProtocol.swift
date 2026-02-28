//
//  FetchSchedulesUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation

/// 월별 내 일정 조회 UseCase Protocol
protocol FetchSchedulesUseCaseProtocol {
    /// 월별 일정 조회
    /// - Parameters:
    ///   - year: 연도 (예: 2026)
    ///   - month: 월 (1~12)
    /// - Returns: 날짜별로 그룹핑된 일정 딕셔너리
    func execute(
        year: Int, month: Int
    ) async throws -> [Date: [ScheduleData]]
}
