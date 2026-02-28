//
//  FetchSessionsUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// 세션 목록 조회 UseCase Protocol
protocol FetchSessionsUseCaseProtocol {
    /// 세션 목록을 조회합니다
    func execute() async throws -> [Session]
}
