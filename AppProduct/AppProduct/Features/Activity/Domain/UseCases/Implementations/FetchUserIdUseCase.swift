//
//  FetchUserIdUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation

/// 현재 사용자 ID 조회 UseCase 구현
final class FetchUserIdUseCase: FetchUserIdUseCaseProtocol {
    private let repository: ActivityRepositoryProtocol

    init(repository: ActivityRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> UserID {
        try await repository.fetchCurrentUserId()
    }
}
