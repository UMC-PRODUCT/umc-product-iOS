//
//  AddChallengerRecordUseCase.swift
//  AppProduct
//
//  Created by Codex on 3/6/26.
//

import Foundation

/// 챌린저 기록 추가 UseCase 구현체
final class AddChallengerRecordUseCase: AddChallengerRecordUseCaseProtocol {

    // MARK: - Property

    private let repository: MyPageRepositoryProtocol

    // MARK: - Init

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(code: String) async throws {
        try await repository.addChallengerRecord(code: code)
    }
}
