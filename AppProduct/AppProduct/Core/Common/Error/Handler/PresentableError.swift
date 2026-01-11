//
//  PresentableError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// View에 표시할 에러 정보
struct PresentableError: Identifiable, Equatable {
    // MARK: - Property

    let id: UUID
    let error: AppError
    let context: ErrorContext
    let dismissAction: () -> Void
    let retryAction: (() async -> Void)?

    // MARK: - Computed Property

    /// Alert 타이틀
    var title: String {
        switch error.severity {
        case .info:
            return "알림"
        case .warning:
            return "오류"
        case .critical:
            return "문제 발생"
        }
    }

    /// 사용자에게 표시할 메시지
    var message: String {
        error.userMessage
    }

    /// 재시도 버튼 표시 여부
    var showRetry: Bool {
        error.isRetryable && retryAction != nil
    }

    // MARK: - Init

    init(
        error: AppError,
        context: ErrorContext,
        dismissAction: @escaping () -> Void,
        retryAction: (() async -> Void)? = nil
    ) {
        self.id = UUID()
        self.error = error
        self.context = context
        self.dismissAction = dismissAction
        self.retryAction = retryAction
    }

    // MARK: - Equatable

    static func == (lhs: PresentableError, rhs: PresentableError) -> Bool {
        lhs.id == rhs.id
    }
}
