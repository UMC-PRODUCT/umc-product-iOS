//
//  ChangeEmailView.swift
//  AuthPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import CoreDI
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 이메일 변경 화면 — 로그인한 회원이 새 이메일을 인증(`CHANGE_EMAIL` 목적)받아 교체한다.
///
/// - Note: 마이페이지에서 push되는 화면이므로 자체 `NavigationStack`을 두지 않는다
///   (`ChangePasswordView`와 동일).
public struct ChangeEmailView: View {

    // MARK: - Property

    @State private var viewModel: ChangeEmailViewModel
    @State private var alertPrompt: AlertPrompt?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Constant

    fileprivate enum Constants {
        static let emailTitle: String = "새 이메일"
        static let emailPlaceholder: String = "example@example.com"
        static let submitTitle: String = "변경하기"
        static let completedTitle: String = "이메일 변경 완료"
        static let completedMessage: String = "이메일이 변경되었습니다."
        static let confirmTitle: String = "확인"
        static let messageLeadingPadding: CGFloat = 10
    }

    // MARK: - Init

    public init(container: DIContainer, errorHandler: ErrorHandler) {
        _viewModel = State(initialValue: ChangeEmailViewModel(
            container: container,
            errorHandler: errorHandler
        ))
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                FormEmailField(
                    title: Constants.emailTitle,
                    placeholder: Constants.emailPlaceholder,
                    text: $viewModel.emailVerificationFlow.email,
                    isVerified: $viewModel.emailVerificationFlow.isEmailVerified,
                    onVerificationRequested: {
                        try await viewModel.emailVerificationFlow.requestEmailVerification()
                    },
                    onVerificationComplete: { code in
                        try await viewModel.emailVerificationFlow.verifyEmailCode(code)
                    },
                    onResend: {
                        try await viewModel.emailVerificationFlow.resendEmailVerification()
                    },
                    submitLabel: .done,
                    onEmailChanged: { viewModel.handleEmailChanged() }
                )

                changeErrorMessageView
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultContentTopMargins)
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigation(naviTitle: NavigationTitle.Auth.changeEmail, displayMode: .inline)
        .safeAreaInset(edge: .bottom) {
            submitButton
        }
        .onChange(of: viewModel.changeEmailState) { _, newState in
            handleChangeEmailStateChange(newState)
        }
        .alertPrompt(item: $alertPrompt)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var changeErrorMessageView: some View {
        if let changeEmailErrorMessage = viewModel.changeEmailErrorMessage {
            Text(changeEmailErrorMessage)
                .appFont(.footnote, color: .red500)
                .padding(.leading, Constants.messageLeadingPadding)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await viewModel.changeEmail() }
        } label: {
            Group {
                if viewModel.changeEmailState.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(Constants.submitTitle)
                        .appFont(.subheadline, weight: .semibold, color: .white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DefaultConstant.defaultBtnPadding)
        }
        .buttonStyle(.glassProminent)
        .tint(.indigo500)
        .disabled(!viewModel.canSubmit || viewModel.changeEmailState.isLoading)
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }

    // MARK: - Function

    private func handleChangeEmailStateChange(_ newState: Loadable<Bool>) {
        guard case .loaded = newState else { return }

        alertPrompt = AlertPrompt(
            title: Constants.completedTitle,
            message: Constants.completedMessage,
            positiveBtnTitle: Constants.confirmTitle,
            positiveBtnAction: { dismiss() }
        )
    }
}
