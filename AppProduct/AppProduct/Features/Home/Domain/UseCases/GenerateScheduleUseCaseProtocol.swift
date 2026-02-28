//
//  GenerateScheduleUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation

/// 일정 생성 UseCase Protocol
protocol GenerateScheduleUseCaseProtocol {
    /// 일정 생성
    /// - Parameter schedule: 일정 생성 요청 DTO
    func execute(schedule: GenerateScheduleRequetDTO) async throws
}
