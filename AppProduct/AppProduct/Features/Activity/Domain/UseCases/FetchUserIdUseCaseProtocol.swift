//
//  FetchUserIdUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// 현재 사용자 ID 조회 UseCase Protocol
protocol FetchUserIdUseCaseProtocol {
    /// 현재 로그인된 사용자의 ID를 조회합니다
    func execute() async throws -> UserID
}
