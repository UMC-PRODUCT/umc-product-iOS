//
//  TokenStore.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

/// Thread-safe 네트워크 클라이언트
/// Actor를 사용하여 토큰 갱신 중복 요청을 자동으로 방지
actor NetworkClient {
    // MARK: - Dependencies
    private let session: URLSession
    private let tokenStore: TokenStore
    private let refreshService: TokenRefreshService
    private let authPolicy: AuthenticationPolicy
    private let maxRetryCount: Int 
    
    private var refreshTask: Task<TokenPair, Error>?
    
    init(
        session: URLSession = .shared,
        tokenStore: TokenStore,
        refreshService: TokenRefreshService,
        authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
        maxRetryCount: Int = 1
    ) {
        self.session = session
        self.tokenStore = tokenStore
        self.refreshService = refreshService
        self.authPolicy = authPolicy
        self.maxRetryCount = maxRetryCount
    }
    
    // MARK: - API
    func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await performRequst(urlRequest, retryCount: 0)
    }
    
    func request<T: Decodable>(_ urlRequest: URLRequest, decoder: JSONDecoder = .init()) async throws -> T {
        let (data, _) = try await request(urlRequest)
        return try decoder.decode(T.self, from: data)
    }
    
    func forceRefreshToken() async throws -> TokenPair {
        try await refreshTokenIssue(force: true)
    }
    
    func logout() async throws {
        refreshTask?.cancel()
        refreshTask = nil 
        try await tokenStore.clear()
        
        #if DEBUG
        print("로그아웃 완료")
        #endif
    }
    
    func isLoggedIn() async -> Bool {
        await tokenStore.getAccessToken() != nil
    }
    
}

// MARK: - Private
extension NetworkClient {
    private func performRequst(
        _ urlRequest: URLRequest,
        retryCount: Int 
    ) async throws -> (Data, HTTPURLResponse) {
        var authenticatedRequest = urlRequest
        
        if authPolicy.requireAuthentication(urlRequest) {
            if let token = await tokenStore.getAccessToken() {
                authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        #if DEBUG
        print("[\(urlRequest.httpMethod ?? "GET")] \(urlRequest.url?.path ?? "")")
        #endif
        
        let (data, response) = try await session.data(for: authenticatedRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        #if DEBUG
        print("Status: \(httpResponse.statusCode)")
        #endif
        
        if authPolicy.isUnauthorizedResponse(httpResponse) {
            guard retryCount < maxRetryCount else {
                throw NetworkError.maxRetryExceeded
            }
            
            #if DEBUG
            print(" 401 감지 → 토큰 갱신 시작")
            #endif
            
            _ = try await refreshTokenIssue(force: true)
            return try await performRequst(urlRequest, retryCount: retryCount +  1)
        }
        
        guard (200...299) .contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode, data: data)
        }
        
        return (data, httpResponse)
    }
    
    private func refreshTokenIssue(force: Bool = false) async throws -> TokenPair {
        if let existingTask = refreshTask {
            #if DEBUG
            print("기존 갱신 Task 대기 중..!")
            #endif
            return try await existingTask.value
        }
        
        let task = Task<TokenPair, Error> {
            defer { refreshTask = nil }
            
            guard let refreshToken = await tokenStore.getRefreshToken() else {
                throw NetworkError.noRefreshToken
            }
            
            do {
                let tokenPair = try await refreshService.refresh(refreshToken)
                try await tokenStore.save(
                    accessToken: tokenPair.accessToken,
                    refreshToken: tokenPair.refreshToken
                )
                
                #if DEBUG
                print("토큰 갱신 성공")
                #endif
                
                return tokenPair
            } catch {
                #if DEBUG
                print("토큰 갱신 실패: \(error)")
                #endif
                throw NetworkError.tokenRefreshFailed(underlying: error)
            }
        }
        
        refreshTask = task 
        return try await task.value
    }
}
