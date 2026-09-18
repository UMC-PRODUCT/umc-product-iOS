//
//  ChangeEmailViewModel.swift
//  AuthPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import AuthDomain
import CoreDI
import Foundation
import UMCFoundation

/// 이메일 변경 화면의 상태 및 액션을 관리하는 ViewModel.
///
/// 흐름: 새 이메일 인증(`CHANGE_EMAIL` 목적) → 변경 요청. 인증 처리는 `EmailVerificationFlow`에
/// 위임한다. 서버가 거절한 변경(이미 사용 중인 이메일 등)은 `ChangePasswordViewModel`과 같이
/// 인라인 메시지로, 그 밖의 실패만 `ErrorHandler`로 처리한다.
@Observable
final class ChangeEmailViewModel {

    // MARK: - Constant

    private enum Constants {
        static let changeFailedMessage: String = "이메일을 변경하지 못했습니다. 다시 시도해 주세요."
        static let action: String = "changeEmail"
    }

    // MARK: - Property

    private let changeEmailUseCase: ChangeEmailUseCaseProtocol
    private let errorHandler: ErrorHandler

    /// 새 이메일 인증(발송·검증·재전송) 상태와 액션 — `EmailVerificationFlow`에 위임한다.
    var emailVerificationFlow: EmailVerificationFlow

    /// 이메일 변경 진행 상태
    private(set) var changeEmailState: Loadable<Bool> = .idle

    /// 변경 실패 인라인 메시지
    private(set) var changeEmailErrorMessage: String?

    // MARK: - Init

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.changeEmailUseCase = container.resolve(ChangeEmailUseCaseProtocol.self)
        self.errorHandler = errorHandler
        self.emailVerificationFlow = EmailVerificationFlow(
            purpose: .changeEmail,
            sendEmailVerificationUseCase: container.resolve(
                SendEmailVerificationUseCaseProtocol.self
            ),
            verifyEmailCodeUseCase: container.resolve(VerifyEmailCodeUseCaseProtocol.self),
            resendEmailVerificationUseCase: container.resolve(
                ResendEmailVerificationUseCaseProtocol.self
            )
        )
    }

    // MARK: - Computed Property

    /// 변경 제출 가능 여부
    var canSubmit: Bool {
        emailVerificationFlow.isEmailVerified &&
        emailVerificationFlow.emailVerificationToken != nil
    }

    // MARK: - Function

    /// 이메일 변경 실행
    @MainActor
    func changeEmail() async {
        guard !changeEmailState.isLoading else { return }
        guard canSubmit,
              let emailVerificationToken = emailVerificationFlow.emailVerificationToken else {
            return
        }

        changeEmailState = .loading
        changeEmailErrorMessage = nil

        do {
            try await changeEmailUseCase.execute(emailVerificationToken: emailVerificationToken)
            changeEmailState = .loaded(true)
        } catch let error as RepositoryError {
            handleChangeFailure(error)
        } catch let error as AppError {
            guard case .repository(let repositoryError) = error else {
                handleUnexpectedFailure(error)
                return
            }
            handleChangeFailure(repositoryError)
        } catch {
            handleUnexpectedFailure(error)
        }
    }

    /// 입력 이메일이 바뀌면 인증 상태와 함께 이전 실패 메시지를 지운다.
    @MainActor
    func handleEmailChanged() {
        emailVerificationFlow.handleEmailChanged()
        changeEmailErrorMessage = nil
    }

    // MARK: - Private Function

    @MainActor
    private func handleChangeFailure(_ error: RepositoryError) {
        if case .serverError(_, let message) = error, let message, !message.isEmpty {
            changeEmailErrorMessage = message
        } else {
            changeEmailErrorMessage = Constants.changeFailedMessage
        }
        changeEmailState = .failed(.repository(error))
    }

    @MainActor
    private func handleUnexpectedFailure(_ error: Error) {
        changeEmailState = .idle
        errorHandler.handle(error, context: ErrorContext(
            feature: "Auth",
            action: Constants.action,
            retryAction: { [weak self] in await self?.changeEmail() }
        ))
    }
}
