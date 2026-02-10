//
//  AuthUseCaseProvider.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// Auth Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol AuthUseCaseProviding {
    /// 소셜 로그인 UseCase
    var loginUseCase: LoginUseCaseProtocol { get }
    /// 내 OAuth 정보 조회 UseCase
    var fetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol { get }
    /// 이메일 인증 발송 UseCase
    var sendEmailVerificationUseCase: SendEmailVerificationUseCaseProtocol { get }
    /// 이메일 인증코드 검증 UseCase
    var verifyEmailCodeUseCase: VerifyEmailCodeUseCaseProtocol { get }
    /// 회원가입 UseCase
    var registerUseCase: RegisterUseCaseProtocol { get }
    /// 회원가입 데이터 조회 UseCase
    var fetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol { get }
}

/// Auth UseCase Provider 구현
///
/// RepositoryProvider와 TokenStore를 주입받아 UseCase들을 생성합니다.
final class AuthUseCaseProvider: AuthUseCaseProviding {

    // MARK: - Property

    let loginUseCase: LoginUseCaseProtocol
    let fetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol
    let sendEmailVerificationUseCase: SendEmailVerificationUseCaseProtocol
    let verifyEmailCodeUseCase: VerifyEmailCodeUseCaseProtocol
    let registerUseCase: RegisterUseCaseProtocol
    let fetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol

    // MARK: - Init

    init(
        repositoryProvider: AuthRepositoryProviding,
        tokenStore: TokenStore
    ) {
        let repository = repositoryProvider.authRepository

        self.loginUseCase = LoginUseCase(
            repository: repository,
            tokenStore: tokenStore
        )
        self.fetchMyOAuthUseCase = FetchMyOAuthUseCase(
            repository: repository
        )
        self.sendEmailVerificationUseCase = SendEmailVerificationUseCase(
            repository: repository
        )
        self.verifyEmailCodeUseCase = VerifyEmailCodeUseCase(
            repository: repository
        )
        self.registerUseCase = RegisterUseCase(
            repository: repository
        )
        self.fetchSignUpDataUseCase = FetchSignUpDataUseCase(
            repository: repository
        )
    }
}
