//
//  FetchMyProfileUseCaseProtocol.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 내 프로필 조회 UseCase Protocol
protocol FetchMyProfileUseCaseProtocol {
    /// 홈 화면 프로필 조회 (기수 카드 + 역할 정보)
    /// - Returns: 기수 카드용 데이터 + 역할별 (challengerId, gisuId) 매핑
    func execute() async throws -> HomeProfileResult
}
