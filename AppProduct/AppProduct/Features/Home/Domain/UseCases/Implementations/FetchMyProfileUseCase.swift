//
//  FetchMyProfileUseCase.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 내 프로필 조회 UseCase 구현
final class FetchMyProfileUseCase: FetchMyProfileUseCaseProtocol {
    private let repository: HomeRepositoryProtocol

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> HomeProfileResult {
        try await repository.getMyProfile()
    }
}
