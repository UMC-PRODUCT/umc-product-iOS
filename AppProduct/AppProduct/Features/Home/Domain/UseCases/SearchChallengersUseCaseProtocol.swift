//
//  SearchChallengersUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 챌린저 검색 UseCase Protocol
///
/// - SeeAlso: ``SearchChallengersUseCase``, ``ChallengerSearchRepositoryProtocol``
protocol SearchChallengersUseCaseProtocol {
    /// 챌린저 검색 실행
    /// - Parameter query: 검색 요청 파라미터
    /// - Returns: (챌린저 목록, 다음 페이지 존재 여부, 다음 페이지 커서)
    func execute(
        query: ChallengerSearchRequestDTO
    ) async throws -> ([ChallengerInfo], hasNext: Bool, nextCursor: Int?)
}
