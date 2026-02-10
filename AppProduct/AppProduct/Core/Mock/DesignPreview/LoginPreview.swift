//
//  LoginPreview.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import Foundation
import SwiftUI

#Preview("로그인") {
    LoginView(
        loginUseCase: PreviewLoginUseCase(),
        errorHandler: ErrorHandler(),
        onLoginSuccess: {},
        onNewMember: { _ in }
    )
}

/// Preview 전용 LoginUseCase
private struct PreviewLoginUseCase: LoginUseCaseProtocol {
    func executeKakao(
        accessToken: String,
        email: String
    ) async throws -> OAuthLoginResult {
        .existingMember(
            tokenPair: TokenPair(
                accessToken: "preview",
                refreshToken: "preview"
            )
        )
    }

    func executeApple(
        authorizationCode: String
    ) async throws -> OAuthLoginResult {
        .existingMember(
            tokenPair: TokenPair(
                accessToken: "preview",
                refreshToken: "preview"
            )
        )
    }
}

#Preview("회원가입") {
    NavigationStack {
        SignUpView(
            oAuthVerificationToken: "preview_token",
            sendEmailVerificationUseCase: PreviewSendEmailUseCase(),
            verifyEmailCodeUseCase: PreviewVerifyCodeUseCase(),
            registerUseCase: PreviewRegisterUseCase(),
            fetchSignUpDataUseCase: PreviewFetchSignUpDataUseCase(),
            onSignUpComplete: {}
        )
    }
}

/// Preview 전용 UseCase들
private struct PreviewSendEmailUseCase: SendEmailVerificationUseCaseProtocol {
    func execute(email: String) async throws -> String {
        "preview_verification_id"
    }
}

private struct PreviewVerifyCodeUseCase: VerifyEmailCodeUseCaseProtocol {
    func execute(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String {
        "preview_email_token"
    }
}

private struct PreviewRegisterUseCase: RegisterUseCaseProtocol {
    func execute(request: RegisterRequestDTO) async throws -> Int {
        1
    }
}

private struct PreviewFetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol {
    func fetchSchools() async throws -> [School] {
        [
            School(id: "1", name: "중앙대학교"),
            School(id: "2", name: "서울대학교")
        ]
    }

    func fetchTerms(termsType: String) async throws -> Terms {
        let type = TermsType(rawValue: termsType) ?? .service
        return Terms(
            id: 1,
            title: "서비스 이용약관",
            content: "<p>약관 내용</p>",
            isMandatory: true,
            termsType: type
        )
    }
}

#Preview("실패시 화면") {
    FailedVerificationUMC()
}

#Preview("승인 대기") {
    PendingApprovalView(onRetryLogin: {})
}

#Preview("홈") {
    NavigationStack {
        HomeView()
    }
    .environment(DIContainer())
    .environment(ErrorHandler())
}
