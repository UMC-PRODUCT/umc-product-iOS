//
//  DefaultAuthenticationPolicy.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

/// 기본 인증 정책 구현체입니다.
///
/// 가장 일반적인 JWT 인증 방식을 따릅니다:
/// - **모든 API 요청에 인증 필요** (로그인/회원가입 API도 포함)
/// - **401 상태 코드를 인증 실패로 간주**
///
/// - Important:
///   - 로그인/회원가입 등 인증 불필요 API가 있다면 커스텀 정책 구현 필요
///   - 403 (Forbidden)도 토큰 갱신 대상으로 하려면 커스텀 정책 구현 필요
///
/// - Usage:
/// ```swift
/// // NetworkClient 초기화 시 기본 정책 사용
/// let networkClient = NetworkClient(
///     tokenStore: tokenStore,
///     refreshService: refreshService,
///     authPolicy: DefaultAuthenticationPolicy()  // 생략 시 자동으로 이 정책 사용
/// )
/// ```
///
/// - Custom Policy Example:
/// ```swift
/// struct CustomAuthenticationPolicy: AuthenticationPolicy {
///     nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
///         // /auth/ 경로는 인증 불필요 (로그인, 회원가입 등)
///         guard let url = request.url?.path else { return true }
///         return !url.contains("/auth/")
///     }
///
///     nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
///         // 401 또는 403을 인증 실패로 간주
///         return response.statusCode == 401 || response.statusCode == 403
///     }
/// }
/// ```
struct DefaultAuthenticationPolicy: AuthenticationPolicy, Sendable {
    // MARK: - Initializer

    /// 기본 인증 정책 초기화
    nonisolated init() {}

    // MARK: - AuthenticationPolicy

    /// 모든 요청에 인증이 필요하다고 판단합니다.
    ///
    /// - Parameter request: 판단할 URLRequest
    ///
    /// - Returns: 항상 `true` (모든 요청에 Authorization 헤더 추가)
    ///
    /// - Note:
    ///   - 로그인/회원가입 API에도 액세스 토큰을 전송하게 됨
    ///   - 실제 서버에서는 로그인 API는 토큰 없이도 동작해야 함
    ///   - 커스텀 정책이 필요하다면 `AuthenticationPolicy` 프로토콜 직접 구현
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
        true
    }

    /// 401 Unauthorized 응답을 인증 실패로 판단합니다.
    ///
    /// - Parameter response: 판단할 HTTPURLResponse
    ///
    /// - Returns:
    ///   - `true`: 상태 코드가 401일 때 (토큰 만료 또는 유효하지 않은 토큰)
    ///   - `false`: 그 외 모든 상태 코드
    ///
    /// - Note:
    ///   - `true` 반환 시 NetworkClient가 자동으로 토큰 갱신 → 재요청
    ///   - 403 (Forbidden)은 갱신 대상이 아님 (권한 부족)
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}
