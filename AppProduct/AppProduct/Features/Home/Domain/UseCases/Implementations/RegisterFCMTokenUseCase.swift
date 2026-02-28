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

    /// FCM 토큰을 서버에 등록/갱신합니다.
    ///
    /// - Parameter fcmToken: Firebase Cloud Messaging 토큰
    func execute(fcmToken: String) async throws {
        try await repository.registerFCMToken(
            fcmToken: fcmToken
        )
    }
}
