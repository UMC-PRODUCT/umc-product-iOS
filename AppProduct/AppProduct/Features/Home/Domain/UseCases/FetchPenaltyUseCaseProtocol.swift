//
//  FetchPenaltyUseCaseProtocol.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 패널티 조회 UseCase Protocol
///
/// API에서 현재 기수 패널티를 받아 CloudKit에 저장하고,
/// 전체 기수 패널티를 로컬에서 조회하여 반환합니다.
protocol FetchPenaltyUseCaseProtocol {
    /// 패널티 데이터 조회 (API → 저장 → 전체 기수 반환)
    /// - Parameters:
    ///   - challengerId: 챌린저 ID
    ///   - gisuId: 기수 식별 ID (RoleDTO에서 전달)
    /// - Returns: 전체 기수 패널티 데이터 목록
    func execute(challengerId: Int, gisuId: Int) async throws -> [GenerationData]
}
