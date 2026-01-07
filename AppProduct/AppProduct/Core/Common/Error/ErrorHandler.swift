//
//  ErrorHandler.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation
import Moya
import os.log

/// 전역 에러 처리기
/// - 에러 로깅, 분석 데이터 수집, 에러 변환을 담당
@Observable
final class ErrorHandler {
    // MARK: - Property

    /// 현재 표시할 에러 (View에서 바인딩)
    private(set) var currentError: PresentableError?

    /// 에러 로거
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "AppProduct",
        category: "ErrorHandler"
    )

    // MARK: - Init

    init() {}

    // MARK: - Error Handling

    /// 에러 처리 진입점
    /// - Parameters:
    ///   - error: 발생한 에러
    ///   - context: 에러 발생 컨텍스트 (화면명, 작업명 등)
    func handle(_ error: Error, context: ErrorContext) {
        let appError = convert(error)

        // 1. 로깅
        log(appError, context: context)

        // 2. 분석 데이터 전송 (선택적)
        trackError(appError, context: context)

        // 3. 특수 처리 (401 -> 로그아웃 등)
        if handleSpecialCases(appError, context: context) {
            return
        }

        // 4. 표시용 에러 설정
        currentError = PresentableError(
            error: appError,
            context: context,
            dismissAction: { [weak self] in
                self?.clearError()
            },
            retryAction: context.retryAction
        )
    }

    /// 에러 초기화
    func clearError() {
        currentError = nil
    }

    // MARK: - Error Conversion

    /// 임의의 Error를 AppError로 변환
    private func convert(_ error: Error) -> AppError {
        // 이미 AppError인 경우
        if let appError = error as? AppError {
            return appError
        }

        // APIError인 경우
        if let apiError = error as? APIError {
            return .api(apiError)
        }

        // ValidationError인 경우
        if let validationError = error as? ValidationError {
            return .validation(validationError)
        }

        // AuthError인 경우
        if let authError = error as? AuthError {
            return .auth(authError)
        }

        // DomainError인 경우
        if let domainError = error as? DomainError {
            return .domain(domainError)
        }

        // MoyaError 변환
        if let moyaError = error as? MoyaError {
            return moyaError.toAppError()
        }

        // URLError 변환
        if let urlError = error as? URLError {
            return .api(convertURLError(urlError))
        }

        // DecodingError 변환
        if let decodingError = error as? DecodingError {
            return .api(.decodingFailed(detail: describeDecodingError(decodingError)))
        }

        // 알 수 없는 에러
        return .unknown(message: error.localizedDescription)
    }

    private func convertURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noNetwork
        case .timedOut:
            return .timeout
        default:
            return .requestFailed(
                statusCode: error.errorCode,
                message: error.localizedDescription
            )
        }
    }

    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _):
            return "Missing key: \(key.stringValue)"
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Type mismatch: expected \(type) at \(path)"
        case .valueNotFound(let type, _):
            return "Value not found: \(type)"
        case .dataCorrupted(let context):
            return "Data corrupted: \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error"
        }
    }

    // MARK: - Logging

    private func log(_ error: AppError, context: ErrorContext) {
        let message = """
        [Error] \(context.feature)/\(context.action)
        - Error: \(error.errorDescription ?? "Unknown")
        - Severity: \(error.severity)
        - Retryable: \(error.isRetryable)
        """

        switch error.severity {
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .critical:
            logger.error("\(message)")
        }
    }

    // MARK: - Analytics

    private func trackError(_ error: AppError, context: ErrorContext) {
        // TODO: Firebase Analytics, Sentry 등 연동 - [25.01.07] 이재원
        // AnalyticsService.track(event: .error(error, context))
    }

    // MARK: - Special Cases

    // TODO: [Refactor] NotificationCenter → AppState + Environment 패턴으로 리팩터링 예정 - [25.01.07] 이재원
    // 현재: NotificationCenter 사용 (타입 안전하지 않음)
    // 개선: AppState를 주입받아 직접 상태 변경 (DIContainer 구현 후)
    //
    // 리팩터링 예시:
    // ```swift
    // private var appState: AppState?
    //
    // case .api(.unauthorized), .auth(.sessionExpired):
    //     appState?.handleSessionExpired()
    //     return true
    // ```

    /// 특수 에러 처리 (true 반환 시 일반 처리 스킵)
    private func handleSpecialCases(_ error: AppError, context: ErrorContext) -> Bool {
        switch error {
        case .api(.unauthorized), .auth(.sessionExpired):
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
            return true

        case .auth(.pendingApproval):
            NotificationCenter.default.post(name: .navigateToPendingApproval, object: nil)
            return true

        default:
            return false
        }
    }
}

// MARK: - Notification Names

// TODO: [Refactor] AppState 도입 후 제거 예정 - [25.01.07] 이재원
extension Notification.Name {
    /// 인증 세션 만료
    static let authSessionExpired = Notification.Name("authSessionExpired")

    /// 승인 대기 화면으로 이동
    static let navigateToPendingApproval = Notification.Name("navigateToPendingApproval")
}
