//
//  FetchCommunitySchoolsUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

final class FetchCommunitySchoolsUseCase: FetchCommunitySchoolsUseCaseProtocol {
    private let repository: CommunityRepositoryProtocol

    init(repository: CommunityRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [String] {
        try await repository.getSchools()
    }
}
