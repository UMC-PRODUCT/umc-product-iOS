//
//  ErrorContext.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// 에러 발생 컨텍스트
/// - 에러가 발생한 위치와 재시도 액션 정보를 담는다
struct ErrorContext: Equatable {
    /// Feature 이름 (예: "Notice", "Auth", "Activity")
    let feature: String

    /// 액션 이름 (예: "fetchList", "login", "submitAttendance")
    let action: String

    /// 재시도 액션 (nil이면 재시도 불가)
    let retryAction: (() async -> Void)?

    // MARK: - Init

    init(
        feature: String,
        action: String,
        retryAction: (() async -> Void)? = nil
    ) {
        self.feature = feature
        self.action = action
        self.retryAction = retryAction
    }

    // MARK: - Equatable

    static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
        lhs.feature == rhs.feature && lhs.action == rhs.action
    }
}
