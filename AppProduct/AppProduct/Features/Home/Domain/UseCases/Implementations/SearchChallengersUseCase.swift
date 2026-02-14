//
//  SearchChallengersUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 챌린저 검색 UseCase 구현
///
/// `ChallengerSearchRepositoryProtocol`에 위임하여 챌린저를 검색합니다.
final class SearchChallengersUseCase: SearchChallengersUseCaseProtocol {

    // MARK: - Property

    private let repository: ChallengerSearchRepositoryProtocol

    // MARK: - Init

    init(repository: ChallengerSearchRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// DTO → Domain 변환 후 커서 정보와 함께 반환
    func execute(
        query: ChallengerSearchRequestDTO
    ) async throws -> ([ChallengerInfo], hasNext: Bool, nextCursor: Int?) {
        let response = try await repository.searchChallengers(query: query)
        let challengers = response.toChallengerInfoList()
        return (challengers, response.cursor.hasNext, response.cursor.nextCursor)
    }
}
