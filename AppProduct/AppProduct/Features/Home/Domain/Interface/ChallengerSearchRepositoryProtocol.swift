//
//  ChallengerSearchRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 챌린저 검색 데이터 접근 Repository Protocol
///
/// HomeRepositoryProtocol에서 챌린저 검색 책임을 분리하여
/// 단일 책임 원칙(SRP)을 강화한 Repository입니다.
protocol ChallengerSearchRepositoryProtocol: Sendable {

    /// 챌린저 검색 (Cursor 기반)
    /// - Parameter query: 챌린저 검색 요청 파라미터
    /// - Returns: 검색 결과 응답 DTO
    func searchChallengers(
        query: ChallengerSearchRequestDTO
    ) async throws -> ChallengerSearchResponseDTO
}
