//
//  TokenPair.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

// MARK: - TokenPair

/// JWT 인증에 사용되는 액세스 토큰과 리프레시 토큰 쌍을 나타냅니다.
///
/// 서버로부터 받은 토큰 쌍을 안전하게 저장하고 전달하기 위한 불변(immutable) 구조체입니다.
///
/// - Important:
///   - **Sendable**: 동시성 환경(async/await, Actor)에서 안전하게 사용 가능
///   - **Codable**: JSON 직렬화/역직렬화 지원 (서버 응답 파싱에 사용)
///   - **nonisolated**: Actor 격리 없이 어디서든 접근 가능
///
/// - Usage:
/// ```swift
/// // 서버 응답 파싱
/// let tokenPair = try JSONDecoder().decode(TokenPair.self, from: data)
///
/// // 토큰 저장
/// await tokenStore.save(
///     accessToken: tokenPair.accessToken,
///     refreshToken: tokenPair.refreshToken
/// )
/// ```
struct TokenPair: Sendable, Codable {
    // MARK: - Property

    /// API 요청 시 사용하는 액세스 토큰
    ///
    /// - Note:
    ///   - HTTP Authorization 헤더에 "Bearer {accessToken}" 형식으로 전송
    ///   - 짧은 유효 기간 (보통 15분~1시간)
    ///   - 만료 시 리프레시 토큰으로 갱신 필요
    public nonisolated let accessToken: String

    /// 액세스 토큰 갱신에 사용하는 리프레시 토큰
    ///
    /// - Note:
    ///   - 액세스 토큰 만료 시 새 토큰 쌍 발급에 사용
    ///   - 긴 유효 기간 (보통 7일~30일)
    ///   - 안전한 저장소(Keychain)에 보관 필수
    public nonisolated let refreshToken: String

    // MARK: - Initializer

    /// TokenPair 초기화
    ///
    /// - Parameters:
    ///   - accessToken: API 요청용 액세스 토큰
    ///   - refreshToken: 토큰 갱신용 리프레시 토큰
    public nonisolated init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
