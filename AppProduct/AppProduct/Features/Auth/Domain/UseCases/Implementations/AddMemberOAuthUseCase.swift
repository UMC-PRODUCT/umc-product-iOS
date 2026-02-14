//
//  AddMemberOAuthUseCase.swift
//  AppProduct
//
//  Created by Codex on 2/15/26.
//

import Foundation

final class AddMemberOAuthUseCase: AddMemberOAuthUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(oAuthVerificationToken: String) async throws -> [MemberOAuth] {
        try await repository.addMemberOAuth(
            oAuthVerificationToken: oAuthVerificationToken
        )
    }
}
