//
//  APIError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// API 통신 관련 에러
enum APIError: Error, LocalizedError, Equatable {
    // MARK: - Network Errors

    /// 잘못된 URL
    case invalidURL

    /// 네트워크 연결 없음
    case noNetwork

    /// 요청 시간 초과
    case timeout

    /// 요청 실패 (상태 코드 및 메시지 포함)
    case requestFailed(statusCode: Int, message: String?)

    // MARK: - Response Errors

    /// 응답 데이터 없음
    case noData

    /// 디코딩 실패
    case decodingFailed(detail: String?)

    // MARK: - HTTP Status Code Errors

    /// 400 Bad Request
    case badRequest(message: String?)

    /// 401 Unauthorized
    case unauthorized

    /// 403 Forbidden
    case forbidden

    /// 404 Not Found
    case notFound

    /// 409 Conflict
    case conflict(message: String?)

    /// 500+ Server Error
    case serverError(code: Int)

    // MARK: - Other

    /// 알 수 없는 에러
    case unknown

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .noNetwork:
            return "네트워크 연결을 확인해주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다."
        case .requestFailed(let code, let message):
            return message ?? "요청 실패 (코드: \(code))"
        case .noData:
            return "데이터가 없습니다."
        case .decodingFailed(let detail):
            return "응답을 해석할 수 없습니다.\(detail.map { " (\($0))" } ?? "")"
        case .badRequest(let message):
            return message ?? "잘못된 요청입니다."
        case .unauthorized:
            return "로그인이 필요합니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .notFound:
            return "요청한 정보를 찾을 수 없습니다."
        case .conflict(let message):
            return message ?? "이미 처리된 요청입니다."
        case .serverError(let code):
            return "서버 오류 (코드: \(code))"
        case .unknown:
            return "알 수 없는 오류입니다."
        }
    }

    // MARK: - User Message

    /// 사용자에게 표시할 친화적 메시지
    var userMessage: String {
        switch self {
        case .noNetwork:
            return "인터넷 연결을 확인해주세요."
        case .timeout:
            return "서버 응답이 늦어지고 있어요. 잠시 후 다시 시도해주세요."
        case .unauthorized:
            return "다시 로그인해주세요."
        case .serverError:
            return "서버에 문제가 있어요. 잠시 후 다시 시도해주세요."
        default:
            return errorDescription ?? "오류가 발생했습니다."
        }
    }

    // MARK: - Severity

    /// 에러 심각도
    var severity: ErrorSeverity {
        switch self {
        case .unauthorized:
            return .critical
        case .noNetwork, .timeout, .serverError:
            return .warning
        default:
            return .info
        }
    }

    // MARK: - Retryable

    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .noNetwork, .timeout, .serverError:
            return true
        default:
            return false
        }
    }

    // MARK: - Factory Methods

    /// HTTP 상태 코드로부터 APIError 생성
    static func from(statusCode: Int, message: String? = nil) -> APIError {
        switch statusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message: message)
        case 500...:
            return .serverError(code: statusCode)
        default:
            return .requestFailed(statusCode: statusCode, message: message)
        }
    }
}
