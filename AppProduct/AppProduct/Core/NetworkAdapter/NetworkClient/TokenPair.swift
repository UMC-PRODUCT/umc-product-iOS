//
//  TokenPair.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

struct TokenPair: Sendable, Codable {
    public nonisolated let accessToken: String
    public nonisolated let refreshToken: String

    public nonisolated init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

enum NetworkError: Error, Sendable {
    case unauthorized
    case tokenRefreshFailed(underlying: Error?)
    case noRefreshToken
    case requestFailed(statusCode: Int, data: Data?)
    case invalidResponse
    case maxRetryExceeded
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "인증이 필요합니다."
        case .tokenRefreshFailed(let error):
            return "토큰 갱신 실패: \(error?.localizedDescription ?? "알수 없음")"
        case .noRefreshToken:
            return "리프레시 토큰이 없습니다."
        case .requestFailed(let statusCode, _):
            return "요청 실패 status: \(statusCode)"
        case .invalidResponse:
            return "잘못된 서버 응답"
        case .maxRetryExceeded:
            return "최대 재시도 횟수 초과"
        }
    }
}
