//
//  LoginActionStack.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 7/9/26.
//

import CoreDesignSystem
import SwiftUI

/// 로그인 액션 영역 — 카카오/Apple/Google 소셜 버튼 + UMC 계정(ID·PW) 진입 + 고객센터 푸터.
///
/// 콜백 기반 dumb 컴포넌트라 여러 화면에서 재사용 가능하다.
public struct LoginActionStack: View {

    // MARK: - Property

    private let isLoading: Bool
    private let loadingMethod: LoginMethod?
    private let onKakaoTap: () -> Void
    private let onAppleTap: () -> Void
    private let onGoogleTap: () -> Void
    private let onEmailTap: () -> Void
    private let onSupportTap: () -> Void

    // MARK: - Init

    public init(
        isLoading: Bool,
        loadingMethod: LoginMethod? = nil,
        onKakaoTap: @escaping () -> Void,
        onAppleTap: @escaping () -> Void,
        onGoogleTap: @escaping () -> Void,
        onEmailTap: @escaping () -> Void,
        onSupportTap: @escaping () -> Void
    ) {
        self.isLoading = isLoading
        self.loadingMethod = loadingMethod
        self.onKakaoTap = onKakaoTap
        self.onAppleTap = onAppleTap
        self.onGoogleTap = onGoogleTap
        self.onEmailTap = onEmailTap
        self.onSupportTap = onSupportTap
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: DefaultSpacing.spacing32) {
            socialLoginSection
            Divider()
            VStack(spacing: DefaultSpacing.spacing12) {
                emailLoginButton
                supportFooter
            }
        }
    }

    // MARK: - Subviews

    private var socialLoginSection: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            kakaoLoginButton
            appleLoginButton
            googleLoginButton
        }
    }

    private var kakaoLoginButton: some View {
        Button(action: onKakaoTap) {
            SocialLoginLabel(.kakao, isLoading: isLoading && loadingMethod == .social(.kakao))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text("카카오로 시작하기"))
        .accessibilityHint(Text("카카오 계정으로 로그인합니다"))
        .accessibilityValue(isLoading && loadingMethod == .social(.kakao) ? "로그인 중" : "")
    }

    private var appleLoginButton: some View {
        Button(action: onAppleTap) {
            SocialLoginLabel(.apple, isLoading: isLoading && loadingMethod == .social(.apple))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text("Apple로 시작하기"))
        .accessibilityHint(Text("Apple 계정으로 로그인합니다"))
        .accessibilityValue(isLoading && loadingMethod == .social(.apple) ? "로그인 중" : "")
    }

    private var googleLoginButton: some View {
        Button(action: onGoogleTap) {
            SocialLoginLabel(.google, isLoading: isLoading && loadingMethod == .social(.google))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text("Google로 시작하기"))
        .accessibilityHint(Text("Google 계정으로 로그인합니다"))
        .accessibilityValue(isLoading && loadingMethod == .social(.google) ? "로그인 중" : "")
        .overlay {
            Capsule()
                .fill(.clear)
                .strokeBorder(Color.grey500, style: .init(lineWidth: 0.5))
        }
    }

    private var emailLoginButton: some View {
        Button(action: onEmailTap) {
            SocialLoginLabel(.email)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(Text("UMC 계정으로 로그인"))
        .accessibilityHint(Text("아이디와 비밀번호 입력 화면으로 이동합니다"))
    }

    private var supportFooter: some View {
        Button(action: onSupportTap) {
            Text("로그인이 안 되나요? \(Text("문의하기").foregroundStyle(Color.indigo).underline())")
            .foregroundStyle(Color.grey600)
            .appFont(.footnote)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: DefaultConstant.minimumTouchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("로그인이 안 되나요? 문의하기")
        .accessibilityHint("카카오톡 UMC 문의 채널을 엽니다")
    }
}

#if DEBUG
#Preview("LoginActionStack") {
    LoginActionStack(
        isLoading: false,
        onKakaoTap: {},
        onAppleTap: {},
        onGoogleTap: {},
        onEmailTap: {},
        onSupportTap: {}
    )
    .padding()
}
#endif
