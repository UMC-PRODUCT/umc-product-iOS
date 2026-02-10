//
//  PendingApprovalView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import SwiftUI

/// 챌린저 승인 대기 화면
///
/// 회원가입 완료 후 운영진의 승인을 기다리는 동안 표시되는 화면입니다.
/// 승인 후 다시 로그인하면 정상적으로 앱에 진입할 수 있습니다.
struct PendingApprovalView: View {

    // MARK: - Property

    /// 다시 로그인 시 호출되는 콜백
    private let onRetryLogin: () -> Void

    // MARK: - Init

    init(onRetryLogin: @escaping () -> Void) {
        self.onRetryLogin = onRetryLogin
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing24) {
            Spacer()

            Image(systemName: "person.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.indigo500)

            VStack(spacing: DefaultSpacing.spacing8) {
                Text("회원가입이 완료되었습니다!")
                    .appFont(.title3Emphasis)

                Text("운영진의 승인을 기다려주세요.\n승인 후 다시 로그인하면 앱을 사용할 수 있습니다.")
                    .appFont(.subheadline, color: .grey600)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            MainButton("다시 로그인", action: {
                onRetryLogin()
            })
            .buttonStyle(.glassProminent)
            .safeAreaPadding(
                .horizontal,
                DefaultConstant.defaultSafeHorizon
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
