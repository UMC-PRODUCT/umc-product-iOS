//
//  ActivityRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// Activity Feature의 데이터 접근을 위한 Repository Protocol
protocol ActivityRepositoryProtocol {
    /// 세션 목록 조회
    func fetchSessions() async throws -> [Session]

    /// 현재 사용자 ID 조회
    func fetchCurrentUserId() async throws -> UserID
}
