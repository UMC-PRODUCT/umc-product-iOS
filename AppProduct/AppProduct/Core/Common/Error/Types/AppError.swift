//
//  AppError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// 앱 전체에서 사용하는 통합 에러 타입
/// - 모든 에러를 래핑하여 일관된 처리 제공
enum AppError: Error, LocalizedError, Equatable {
    /// API 통신 에러
    case api(APIError)

    /// 입력 유효성 검증 에러
    case validation(ValidationError)

    /// 인증 관련 에러
    case auth(AuthError)

    /// 도메인(비즈니스) 에러
    case domain(DomainError)

    /// 알 수 없는 에러
    case unknown(message: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .api(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        case .auth(let error):
            return error.errorDescription
        case .domain(let error):
            return error.errorDescription
        case .unknown(let message):
            return message
        }
    }

    // MARK: - User Message

    /// 사용자에게 표시할 친화적 메시지
    var userMessage: String {
        switch self {
        case .api(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .auth(let error):
            return error.userMessage
        case .domain(let error):
            return error.userMessage
        case .unknown:
            return "일시적인 오류가 발생했습니다. 다시 시도해주세요."
        }
    }

    // MARK: - Severity

    /// 에러 심각도 (표시 방식 결정에 사용)
    var severity: ErrorSeverity {
        switch self {
        case .api(let error):
            return error.severity
        case .validation:
            return .warning
        case .auth:
            return .critical
        case .domain:
            return .info
        case .unknown:
            return .warning
        }
    }

    // MARK: - Retryable

    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .api(let error):
            return error.isRetryable
        case .validation:
            return false
        case .auth:
            return false
        case .domain:
            return false
        case .unknown:
            return true
        }
    }
}
