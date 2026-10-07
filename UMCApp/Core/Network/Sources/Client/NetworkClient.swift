//
//  NetworkClient.swift
//  CoreNetwork
//
//  Created by euijjang97 on 4/25/26.
//

import Aquila
import Foundation
import UMCFoundation

public actor NetworkClient {
    // MARK: - Property

    nonisolated let aquilaClient: Aquila.NetworkClient
    nonisolated static let logger = Aquila.VerboseLogger(redactedKeys: [
        "authorizationCode", "oAuthVerificationToken", "emailVerificationToken",
        "googleAccessToken", "kakaoAccessToken", "rawPassword", "currentPassword", "newPassword",
        "verificationCode", "code"
    ])

    // MARK: - Init

    public init(
        session: URLSession = .shared,
        tokenStore: TokenStore,
        refreshService: TokenRefreshService,
        authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
        maxRetryCount: Int = 1
    ) {
        aquilaClient = Aquila.NetworkClient(
            session: session,
            tokenStore: tokenStore,
            refreshService: AppTokenRefreshService(service: refreshService),
            authPolicy: authPolicy,
            maxRetryCount: maxRetryCount,
            sessionResetter: AppSessionResetter(),
            logger: Self.logger
        )
    }

    // MARK: - Function

    public func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await aquilaClient.request(urlRequest)
        } catch {
            throw Self.appError(from: error)
        }
    }

    public func request<T: Decodable>(
        _ urlRequest: URLRequest,
        decoder: JSONDecoder = .init()
    ) async throws -> T {
        let (data, _) = try await request(urlRequest)
        return try decoder.decode(T.self, from: data)
    }

    public func forceRefreshToken() async throws -> TokenPair {
        do {
            return try await aquilaClient.forceRefreshToken()
        } catch {
            throw Self.appError(from: error)
        }
    }

    public func logout() async throws {
        do {
            try await aquilaClient.logout()
        } catch {
            throw Self.appError(from: error)
        }
    }

    public func isLoggedIn() async -> Bool {
        await aquilaClient.hasAccessToken()
    }

    nonisolated static func appError(
        from error: Error,
        refreshing: Bool = false
    ) -> Error {
        if let networkError = error as? Aquila.NetworkError {
            switch networkError {
            case .invalidResponse, .authenticationNotConfigured:
                return UMCFoundation.NetworkError.invalidResponse
            case .noRefreshToken:
                return UMCFoundation.NetworkError.noRefreshToken
            case .maxRetryExceeded:
                return UMCFoundation.NetworkError.maxRetryExceeded
            case .requestFailed(let statusCode, let data):
                if refreshing, statusCode == 401 || statusCode == 403 {
                    return UMCFoundation.NetworkError.tokenRefreshFailed(
                        reason: "서버 에러 (status: \(statusCode))"
                    )
                }
                return UMCFoundation.NetworkError.requestFailed(statusCode: statusCode, data: data)
            }
        }
        if let refreshError = error as? TokenRefreshError {
            switch refreshError {
            case .invalidResponse:
                return UMCFoundation.NetworkError.invalidResponse
            case .serverError(let statusCode):
                if refreshing, statusCode == 401 || statusCode == 403 {
                    return UMCFoundation.NetworkError.tokenRefreshFailed(
                        reason: refreshError.errorDescription
                    )
                }
                return UMCFoundation.NetworkError.requestFailed(statusCode: statusCode, data: nil)
            case .refreshFailed(let message):
                return RepositoryError.serverError(code: nil, message: message)
            }
        }
        if let urlError = error as? URLError {
            return UMCFoundation.NetworkError.transientFailure(from: urlError) ?? urlError
        }
        return error
    }
}

private struct AppTokenRefreshService: TokenRefreshService {
    let service: TokenRefreshService

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        do {
            return try await service.refresh(refreshToken)
        } catch {
            throw NetworkClient.appError(from: error, refreshing: true)
        }
    }
}

private struct AppSessionResetter: Aquila.SessionResetting {
    func resetSession() async {
        AppStorageKey.clearSessionScopedValues()
    }
}
