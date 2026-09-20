//
//  ChangePasswordViewModelTests.swift
//  AuthPresentationTests
//
//  Created by euijjang97 on 9/19/26.
//

import Testing
import Foundation
import CoreDI
import AuthDomain
import UMCFoundation
@testable import AuthPresentation

@MainActor
@Suite("ChangePasswordViewModel — 최초 등록 모드")
struct ChangePasswordViewModelRegisterModeTests {

    @Test("현재 비밀번호 없이 새 비밀번호만으로 제출할 수 있고 등록 UseCase를 호출한다")
    func registerModeSubmitsWithoutCurrentPassword() async {
        let changePasswordUseCase = SpyChangePasswordUseCase()
        let registerCredentialUseCase = SpyRegisterCredentialUseCase()
        let viewModel = makeViewModel(
            mode: .register,
            changePasswordUseCase: changePasswordUseCase,
            registerCredentialUseCase: registerCredentialUseCase
        )
        viewModel.newPassword = "password1234"

        #expect(viewModel.canSubmit)
        await viewModel.submit()

        #expect(registerCredentialUseCase.receivedPasswords == ["password1234"])
        #expect(changePasswordUseCase.callCount == 0)
        #expect(viewModel.changePasswordState == .loaded(true))
    }

    @Test("변경 모드는 현재 비밀번호가 비어 있으면 제출할 수 없다")
    func changeModeRequiresCurrentPassword() {
        let viewModel = makeViewModel(mode: .change)
        viewModel.newPassword = "password1234"

        #expect(!viewModel.canSubmit)
    }

    @Test("서버가 등록을 거절하면 서버 메시지를 인라인으로 보여 준다")
    func registerModeShowsServerMessageInline() async {
        let registerCredentialUseCase = SpyRegisterCredentialUseCase()
        registerCredentialUseCase.error = RepositoryError.serverError(
            code: "CREDENTIAL_ALREADY_REGISTERED",
            message: "이미 비밀번호가 등록되어 있습니다."
        )
        let viewModel = makeViewModel(
            mode: .register,
            registerCredentialUseCase: registerCredentialUseCase
        )
        viewModel.newPassword = "password1234"

        await viewModel.submit()

        #expect(viewModel.changePasswordErrorMessage == "이미 비밀번호가 등록되어 있습니다.")
    }
}

// MARK: - Test Doubles

private final class SpyChangePasswordUseCase: ChangePasswordUseCaseProtocol,
    @unchecked Sendable {
    private(set) var callCount = 0

    func execute(currentPassword: String, newPassword: String) async throws {
        callCount += 1
    }
}

private final class SpyRegisterCredentialUseCase: RegisterCredentialUseCaseProtocol,
    @unchecked Sendable {
    var error: Error?
    private(set) var receivedPasswords: [String] = []

    func execute(rawPassword: String) async throws {
        receivedPasswords.append(rawPassword)
        if let error { throw error }
    }
}

// MARK: - Helper

private func makeViewModel(
    mode: ChangePasswordMode,
    changePasswordUseCase: ChangePasswordUseCaseProtocol = SpyChangePasswordUseCase(),
    registerCredentialUseCase: RegisterCredentialUseCaseProtocol = SpyRegisterCredentialUseCase()
) -> ChangePasswordViewModel {
    let container = DIContainer()
    container.register(ChangePasswordUseCaseProtocol.self) { changePasswordUseCase }
    container.register(RegisterCredentialUseCaseProtocol.self) { registerCredentialUseCase }

    return ChangePasswordViewModel(container: container, errorHandler: ErrorHandler(), mode: mode)
}
