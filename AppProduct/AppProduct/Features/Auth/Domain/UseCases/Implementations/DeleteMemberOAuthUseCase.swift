//
//  DeleteMemberOAuthUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 3/10/26.
//

import Foundation

/// OAuth 수단 연동 해제 UseCase 구현체
final class DeleteMemberOAuthUseCase: DeleteMemberOAuthUseCaseProtocol {
    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(
        memberOAuthId: Int,
        googleAccessToken: String?,
        kakaoAccessToken: String?
    ) async throws {
        try await repository.deleteMemberOAuth(
            memberOAuthId: memberOAuthId,
            googleAccessToken: googleAccessToken,
            kakaoAccessToken: kakaoAccessToken
        )
    }
}
