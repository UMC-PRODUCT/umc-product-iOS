//
//  UpdateScheduleUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 일정 수정 UseCase Protocol
protocol UpdateScheduleUseCaseProtocol {
    // MARK: - Function

    /// 일정 수정
    /// - Parameters:
    ///   - scheduleId: 수정할 일정 ID
    ///   - schedule: 일정 수정 요청 DTO
    /// - Throws: 서버 에러 또는 네트워크 에러
    func execute(scheduleId: Int, schedule: UpdateScheduleRequestDTO) async throws
}
