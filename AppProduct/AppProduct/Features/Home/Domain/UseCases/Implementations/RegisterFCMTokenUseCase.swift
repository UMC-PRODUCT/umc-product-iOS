//
//  RegisterFCMTokenUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/14/26.
//

import Foundation

/// FCM 토큰 등록 UseCase 구현체
final class RegisterFCMTokenUseCase: RegisterFCMTokenUseCaseProtocol {

    // MARK: - Property

    private let repository: HomeRepositoryProtocol

    // MARK: - Init

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(challengerId: Int, fcmToken: String) async throws {
        try await repository.registerFCMToken(
            challengerId: challengerId,
            fcmToken: fcmToken
        )
    }
}
