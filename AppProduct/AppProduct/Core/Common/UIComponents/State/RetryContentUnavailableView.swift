//
//  RetryContentUnavailableView.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import SwiftUI

/// 로딩 실패 시 재시도 액션을 함께 제공하는 공통 Unavailable View입니다.
struct RetryContentUnavailableView: View {

    // MARK: - Property
    let title: String
    let systemImage: String
    let description: String
    let retryTitle: String
    let isRetrying: Bool
    let minRetryButtonWidth: CGFloat
    let minRetryButtonHeight: CGFloat
    let topPadding: CGFloat
    let retryAction: () async -> Void

    // MARK: - Initializer
    init(
        title: String,
        systemImage: String,
        description: String,
        retryTitle: String = "다시 시도",
        isRetrying: Bool,
        minRetryButtonWidth: CGFloat = 72,
        minRetryButtonHeight: CGFloat = 20,
        topPadding: CGFloat = .zero,
        retryAction: @escaping () async -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.retryTitle = retryTitle
        self.isRetrying = isRetrying
        self.minRetryButtonWidth = minRetryButtonWidth
        self.minRetryButtonHeight = minRetryButtonHeight
        self.topPadding = topPadding
        self.retryAction = retryAction
    }

    // MARK: - Body
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
                .multilineTextAlignment(.center)
        } actions: {
            Button {
                Task {
                    await retryAction()
                }
            } label: {
                ZStack {
                    Text(retryTitle)
                        .opacity(isRetrying ? 0 : 1)
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(
                    minWidth: minRetryButtonWidth,
                    minHeight: minRetryButtonHeight
                )
            }
            .buttonStyle(.glassProminent)
            .disabled(isRetrying)
        }
        .padding(.top, topPadding)
    }
}
