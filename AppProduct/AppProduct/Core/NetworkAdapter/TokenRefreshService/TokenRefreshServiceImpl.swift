//
//  TokenRefreshServiceImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

struct TokenRefreshServiceImpl: TokenRefreshService {
   
    private let baseURL: URL 
    private let session: URLSession
    private let decoder: JSONDecoder
    
    nonisolated init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }
    
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        let url = baseURL.appending(path: "auth/reissue")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TokenRefreshError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let tokenResponse = try decoder.decode(CommonDTO<TokenResult>.self, from: data)
        
        guard tokenResponse.isSuccess, let result = tokenResponse.result else {
            throw TokenRefreshError.refreshFailed(message: tokenResponse.message)
        }
        
        return TokenPair(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken
        )
    }
}

private struct TokenResult: Codable {
    let accessToken: String
    let refreshToken: String
}

public enum TokenRefreshError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case refreshFailed(message: String?)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "잘못된 서버 응답"
        case .serverError(let statusCode):
            return "서버 에러 (status: \(statusCode))"
        case .refreshFailed(let message):
            return message ?? "토큰 갱신 실패"
        }
    }
}
