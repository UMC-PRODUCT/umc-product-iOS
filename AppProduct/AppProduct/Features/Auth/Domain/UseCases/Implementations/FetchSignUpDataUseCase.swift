//
//  FetchSignUpDataUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - FetchSignUpDataUseCase

/// 회원가입 데이터 조회 UseCase 구현체
final class FetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func fetchSchools() async throws -> [School] {
        try await repository.getSchools()
    }

    func fetchTerms(termsType: String) async throws -> Terms {
        try await repository.getTerms(termsType: termsType)
    }
}
