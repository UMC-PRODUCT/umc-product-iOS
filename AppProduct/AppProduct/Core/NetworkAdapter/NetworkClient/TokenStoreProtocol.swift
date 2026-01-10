//
//  TokenStoreProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

/// 토큰 저장소 프로토콜
protocol TokenStore: Sendable {
    func getAccessToken() async -> String?
    func getRefreshToken()  async -> String?
    func save(accessToken: String, refreshToken: String) async throws
    func clear() async throws
}

protocol TokenRefreshService: Sendable {
    func refresh(_ refreshToken: String) async throws -> TokenPair
}

protocol AuthenticationPolicy: Sendable {
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool
}
