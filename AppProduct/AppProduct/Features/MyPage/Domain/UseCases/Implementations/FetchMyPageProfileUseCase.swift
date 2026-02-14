//
//  FetchMyPageProfileUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class FetchMyPageProfileUseCase: FetchMyPageProfileUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> ProfileData {
        try await repository.fetchMyProfile()
    }
}
