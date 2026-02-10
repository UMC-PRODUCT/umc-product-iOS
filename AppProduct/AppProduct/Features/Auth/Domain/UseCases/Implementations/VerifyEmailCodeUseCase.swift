//
//  VerifyEmailCodeUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - VerifyEmailCodeUseCase

/// 이메일 인증코드 검증 UseCase 구현체
final class VerifyEmailCodeUseCase: VerifyEmailCodeUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        try await repository.verifyEmailCode(
            emailVerificationId: emailVerificationId,
            verificationCode: verificationCode
        )
    }
}
