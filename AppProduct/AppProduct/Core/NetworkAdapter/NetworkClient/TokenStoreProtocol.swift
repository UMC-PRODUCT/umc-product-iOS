//
//  TokenStoreProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

// MARK: - TokenStore

/// JWT 토큰을 안전하게 저장하고 관리하는 저장소 프로토콜입니다.
///
/// 액세스 토큰과 리프레시 토큰을 영구 저장소(Keychain, UserDefaults 등)에 저장하고,
/// NetworkClient가 인증이 필요한 API 호출 시 토큰을 제공합니다.
///
/// - Important:
///   - **Sendable**: Actor와 안전하게 상호작용 가능
///   - **async 메서드**: 저장소 접근은 비동기로 처리 (I/O 작업)
///   - **Keychain 권장**: 민감한 토큰 정보는 Keychain에 저장 필수
///
/// - Implementation Example:
/// ```swift
/// actor KeychainTokenStore: TokenStore {
///     private let keychain = KeychainWrapper.standard
///
///     func getAccessToken() async -> String? {
///         keychain.string(forKey: "accessToken")
///     }
///
///     func getRefreshToken() async -> String? {
///         keychain.string(forKey: "refreshToken")
///     }
///
///     func save(accessToken: String, refreshToken: String) async throws {
///         keychain.set(accessToken, forKey: "accessToken")
///         keychain.set(refreshToken, forKey: "refreshToken")
///     }
///
///     func clear() async throws {
///         keychain.removeObject(forKey: "accessToken")
///         keychain.removeObject(forKey: "refreshToken")
///     }
/// }
/// ```
///
/// - Usage:
/// ```swift
/// let tokenStore = KeychainTokenStore()
///
/// // 토큰 저장 (로그인 성공 시)
/// try await tokenStore.save(
///     accessToken: "eyJhbGc...",
///     refreshToken: "dGhpcyBp..."
/// )
///
/// // 토큰 조회 (API 요청 시)
/// if let accessToken = await tokenStore.getAccessToken() {
///     request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
/// }
///
/// // 토큰 삭제 (로그아웃 시)
/// try await tokenStore.clear()
/// ```
protocol TokenStore: Sendable {
    /// 저장된 액세스 토큰을 반환합니다.
    ///
    /// - Returns: 저장된 액세스 토큰, 없으면 nil
    ///
    /// - Note: NetworkClient가 API 요청 시 Authorization 헤더에 사용합니다.
    func getAccessToken() async -> String?

    /// 저장된 리프레시 토큰을 반환합니다.
    ///
    /// - Returns: 저장된 리프레시 토큰, 없으면 nil
    ///
    /// - Note: 액세스 토큰 만료(401) 시 토큰 갱신에 사용합니다.
    func getRefreshToken() async -> String?

    /// 액세스 토큰과 리프레시 토큰을 저장합니다.
    ///
    /// - Parameters:
    ///   - accessToken: API 요청용 액세스 토큰
    ///   - refreshToken: 토큰 갱신용 리프레시 토큰
    ///
    /// - Throws: 저장소 쓰기 실패 시 에러 발생
    ///
    /// - Note:
    ///   - 로그인 성공 시 호출
    ///   - 토큰 갱신 성공 시 호출 (기존 토큰 덮어쓰기)
    func save(accessToken: String, refreshToken: String) async throws

    /// 저장된 모든 토큰을 삭제합니다.
    ///
    /// - Throws: 저장소 삭제 실패 시 에러 발생
    ///
    /// - Note:
    ///   - 로그아웃 시 호출
    ///   - 회원 탈퇴 시 호출
    func clear() async throws
}

// MARK: - TokenRefreshService

/// 리프레시 토큰으로 새로운 토큰 쌍을 발급받는 서비스 프로토콜입니다.
///
/// 액세스 토큰 만료(401) 시 서버의 토큰 갱신 API를 호출하여
/// 새로운 액세스 토큰과 리프레시 토큰을 발급받습니다.
///
/// - Important:
///   - **Sendable**: NetworkClient(Actor)에서 안전하게 호출 가능
///   - **서버 API 의존**: 서버의 토큰 갱신 엔드포인트 구현 필요
///
/// - Implementation Example:
/// ```swift
/// struct DefaultTokenRefreshService: TokenRefreshService {
///     private let baseURL = "https://api.example.com"
///
///     func refresh(_ refreshToken: String) async throws -> TokenPair {
///         var request = URLRequest(url: URL(string: "\(baseURL)/auth/refresh")!)
///         request.httpMethod = "POST"
///         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
///
///         let body = ["refreshToken": refreshToken]
///         request.httpBody = try JSONEncoder().encode(body)
///
///         let (data, response) = try await URLSession.shared.data(for: request)
///
///         guard let httpResponse = response as? HTTPURLResponse,
///               (200...299).contains(httpResponse.statusCode) else {
///             throw NetworkError.tokenRefreshFailed(underlying: nil)
///         }
///
///         return try JSONDecoder().decode(TokenPair.self, from: data)
///     }
/// }
/// ```
///
/// - Usage:
/// ```swift
/// let refreshService = DefaultTokenRefreshService()
///
/// do {
///     let newTokenPair = try await refreshService.refresh(oldRefreshToken)
///     await tokenStore.save(
///         accessToken: newTokenPair.accessToken,
///         refreshToken: newTokenPair.refreshToken
///     )
/// } catch {
///     // 갱신 실패 → 재로그인 필요
///     print("토큰 갱신 실패: \(error)")
/// }
/// ```
protocol TokenRefreshService: Sendable {
    /// 리프레시 토큰으로 새로운 토큰 쌍을 발급받습니다.
    ///
    /// - Parameter refreshToken: 현재 저장된 리프레시 토큰
    ///
    /// - Returns: 새로 발급받은 액세스 토큰과 리프레시 토큰 쌍
    ///
    /// - Throws:
    ///   - `NetworkError.tokenRefreshFailed`: 토큰 갱신 API 호출 실패
    ///   - 네트워크 에러, 디코딩 에러 등
    ///
    /// - Note:
    ///   - NetworkClient가 401 응답 수신 시 자동으로 호출
    ///   - 갱신 실패 시 사용자 재로그인 필요
    func refresh(_ refreshToken: String) async throws -> TokenPair
}

// MARK: - AuthenticationPolicy

/// API 요청의 인증 정책을 정의하는 프로토콜입니다.
///
/// 어떤 요청에 인증이 필요한지, 어떤 응답이 인증 실패인지를 판단하는 로직을 제공합니다.
///
/// - Important:
///   - **Sendable**: NetworkClient(Actor)에서 안전하게 호출 가능
///   - **nonisolated**: Actor 격리 없이 동기적으로 호출 가능
///
/// - Default Implementation:
///   - `DefaultAuthenticationPolicy`: 모든 요청 인증 필요, 401 응답을 인증 실패로 간주
///
/// - Custom Implementation Example:
/// ```swift
/// struct CustomAuthenticationPolicy: AuthenticationPolicy {
///     nonisolated func requireAuthentication(_ request: URLRequest) -> Bool {
///         // 로그인, 회원가입 API는 인증 불필요
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
///
/// - Usage:
/// ```swift
/// // 기본 정책 사용
/// let networkClient = NetworkClient(
///     tokenStore: tokenStore,
///     refreshService: refreshService,
///     authPolicy: DefaultAuthenticationPolicy()
/// )
///
/// // 커스텀 정책 사용
/// let networkClient = NetworkClient(
///     tokenStore: tokenStore,
///     refreshService: refreshService,
///     authPolicy: CustomAuthenticationPolicy()
/// )
/// ```
protocol AuthenticationPolicy: Sendable {
    /// 주어진 요청에 인증(Authorization 헤더)이 필요한지 판단합니다.
    ///
    /// - Parameter request: 판단할 URLRequest
    ///
    /// - Returns:
    ///   - `true`: 액세스 토큰을 Authorization 헤더에 추가
    ///   - `false`: 인증 없이 요청 전송 (로그인, 회원가입 등)
    ///
    /// - Note: NetworkClient가 요청 전송 전에 호출합니다.
    nonisolated func requireAuthentication(_ request: URLRequest) -> Bool

    /// 주어진 응답이 인증 실패(Unauthorized) 응답인지 판단합니다.
    ///
    /// - Parameter response: 판단할 HTTPURLResponse
    ///
    /// - Returns:
    ///   - `true`: 토큰 갱신 후 재시도
    ///   - `false`: 정상 응답 또는 다른 에러
    ///
    /// - Note:
    ///   - NetworkClient가 응답 수신 후 호출
    ///   - `true` 반환 시 자동으로 토큰 갱신 → 재요청
    nonisolated func isUnauthorizedResponse(_ response: HTTPURLResponse) -> Bool
}
