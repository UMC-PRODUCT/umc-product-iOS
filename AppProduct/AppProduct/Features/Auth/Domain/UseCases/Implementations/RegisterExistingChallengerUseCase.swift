//
//  RegisterExistingChallengerUseCase.swift
//  AppProduct
//
//  Created by Codex on 2/15/26.
//

import Foundation

/// 기존 챌린저 인증 코드 등록 UseCase 구현체
final class RegisterExistingChallengerUseCase: RegisterExistingChallengerUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(code: String) async throws {
        try await repository.registerExistingChallenger(code: code)
    }
}
