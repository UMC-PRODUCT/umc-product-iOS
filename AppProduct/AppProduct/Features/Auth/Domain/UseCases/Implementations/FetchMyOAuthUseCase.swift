//
//  FetchMyOAuthUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

// MARK: - FetchMyOAuthUseCase

/// 내 OAuth 연동 정보 조회 UseCase 구현체
final class FetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute() async throws -> [MemberOAuth] {
        try await repository.getMyOAuth()
    }
}
