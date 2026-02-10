//
//  FetchMyOAuthUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

// MARK: - Protocol

/// 내 OAuth 연동 정보 조회 UseCase Protocol
protocol FetchMyOAuthUseCaseProtocol {
    /// 내 OAuth 연동 정보 조회
    /// - Returns: OAuth 연동 정보 목록
    func execute() async throws -> [MemberOAuth]
}
