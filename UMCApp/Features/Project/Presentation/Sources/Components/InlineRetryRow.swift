//
//  InlineRetryRow.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

/// 리스트 섹션 하나만 실패했을 때 그 자리에 두는 에러 문구 + 다시 시도 행.
///
/// 화면 전체가 실패하면 `RetryContentUnavailableView` 를 쓴다.
struct InlineRetryRow: View {

    // MARK: - Property

    let error: AppError
    let retry: @MainActor () async -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            Text(error.userMessage)
                .appFont(.footnote, color: .grey500)
            Spacer()
            Button("다시 시도") {
                Task { await retry() }
            }
            .buttonStyle(.borderless)
        }
    }
}
