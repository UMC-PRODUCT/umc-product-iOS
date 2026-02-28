//
//  FetchSessionsUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// 세션 목록 조회 UseCase 구현
final class FetchSessionsUseCase: FetchSessionsUseCaseProtocol {
    private let repository: ActivityRepositoryProtocol

    init(repository: ActivityRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Session] {
        try await repository.fetchSessions()
    }
}
