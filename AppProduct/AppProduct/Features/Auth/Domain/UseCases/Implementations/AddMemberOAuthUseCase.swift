//
//  AddMemberOAuthUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// OAuth 수단 추가 연동 UseCase 구현체
///
/// AuthRepository를 통해 서버에 OAuth 연동 추가 요청을 수행합니다.
final class AddMemberOAuthUseCase: AddMemberOAuthUseCaseProtocol {
    // MARK: - Property

    private let repository: AuthRepositoryProtocol

    // MARK: - Init

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    /// OAuth 검증 토큰으로 소셜 계정 연동을 추가합니다.
    ///
    /// - Parameter oAuthVerificationToken: 소셜 로그인 시 발급받은 검증 토큰
    /// - Returns: 연동된 전체 OAuth 목록
    /// - Throws: 네트워크 에러 또는 서버 에러
    func execute(oAuthVerificationToken: String) async throws -> [MemberOAuth] {
        try await repository.addMemberOAuth(
            oAuthVerificationToken: oAuthVerificationToken
        )
    }
}
