//
//  FetchTermsUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class FetchTermsUseCase: FetchTermsUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute(termsType: String) async throws -> MyPageTerms {
        try await repository.fetchTerms(termsType: termsType)
    }
}
