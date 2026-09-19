//
//  ChangeEmailUseCase.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDomain

/// 이메일 변경 UseCase 구현체
public final class ChangeEmailUseCase: ChangeEmailUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol
    private let memberProfileRepository: MemberProfileRepositoryProtocol

    // MARK: - Init

    public init(
        repository: AuthRepositoryProtocol,
        memberProfileRepository: MemberProfileRepositoryProtocol
    ) {
        self.repository = repository
        self.memberProfileRepository = memberProfileRepository
    }

    // MARK: - Function

    public func execute(emailVerificationToken: String) async throws {
        try await repository.changeEmail(emailVerificationToken: emailVerificationToken)
        await memberProfileRepository.invalidateCache()
    }
}
