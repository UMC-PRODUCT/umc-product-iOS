//
//  FetchHasLocalCredentialUseCase.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

/// 로컬(이메일/비밀번호) 자격증명 보유 여부 조회 UseCase 구현체
public final class FetchHasLocalCredentialUseCase: FetchHasLocalCredentialUseCaseProtocol {

    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func execute() async throws -> Bool {
        try await repository.fetchHasLocalCredential()
    }
}
