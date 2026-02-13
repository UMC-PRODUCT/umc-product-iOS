//
//  FetchPenaltyUseCase.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 패널티 조회 UseCase 구현
///
/// 1. API에서 현재 기수 패널티 조회
/// 2. CloudKit(SwiftData)에 저장 (upsert)
/// 3. 전체 기수 패널티를 로컬에서 조회하여 반환
final class FetchPenaltyUseCase: FetchPenaltyUseCaseProtocol {
    private let homeRepository: HomeRepositoryProtocol
    private let genRepository: ChallengerGenRepositoryProtocol

    init(
        homeRepository: HomeRepositoryProtocol,
        genRepository: ChallengerGenRepositoryProtocol
    ) {
        self.homeRepository = homeRepository
        self.genRepository = genRepository
    }

    func execute(challengerId: Int, gisuId: Int) async throws -> [GenerationData] {
        let currentPenalty = try await homeRepository.getPenalty(
            challengerId: challengerId,
            gisuId: gisuId
        )
        try genRepository.savePenalty(currentPenalty)
        return try genRepository.fetchAllPenalties()
    }
}
