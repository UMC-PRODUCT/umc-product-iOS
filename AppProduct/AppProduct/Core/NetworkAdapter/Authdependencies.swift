//
//  Authdependencies.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation
import Moya

/// 인증 시스템 관련 의존성을 생성하는 팩토리입니다.
///
/// NetworkClient와 관련 의존성(TokenStore, TokenRefreshService)을 올바르게 조립하여 생성합니다.
///
/// - Important:
///   - **프로덕션**: `makeNetworkClient(baseURL:)` 사용
///   - **테스트**: `makeTestNetworkClient(tokenStore:refreshService:)` 사용
///
/// - Usage:
/// ```swift
/// // DIContainer에서 사용
/// class DIContainer {
///     lazy var networkClient: NetworkClient = {
///         AuthSystemFactory.makeNetworkClient(
///             baseURL: URL(string: "https://api.umc.com")!
///         )
///     }()
/// }
/// ```
enum AuthSystemFactory {
    // MARK: - Factory Methods

    /// 프로덕션 환경용 NetworkClient를 생성합니다.
    ///
    /// 실제 서버와 통신하는 완전한 NetworkClient를 생성합니다.
    ///
    /// - Parameters:
    ///   - baseURL: API 서버 기본 URL
    ///   - session: URLSession (기본값: .shared)
    ///   - tokenStore: 외부 주입 TokenStore (nil이면 내부 생성)
    ///
    /// - Returns: 완전히 구성된 NetworkClient 인스턴스
    ///
    /// - Important:
    ///   - TokenStore: KeychainTokenStore 사용 (보안)
    ///   - TokenRefreshService: TokenRefreshServiceImpl 사용 (실제 서버 호출)
    ///   - AuthenticationPolicy: DefaultAuthenticationPolicy 사용 (모든 요청 인증)
    ///
    /// ## 구성 요소
    ///
    /// ```
    /// NetworkClient
    ///     ├── URLSession (.shared)
    ///     ├── TokenStore (KeychainTokenStore)
    ///     ├── TokenRefreshService (TokenRefreshServiceImpl)
    ///     └── AuthenticationPolicy (DefaultAuthenticationPolicy)
    /// ```
    ///
    /// - Usage:
    /// ```swift
    /// let networkClient = AuthSystemFactory.makeNetworkClient(
    ///     baseURL: URL(string: "https://api.umc.com")!
    /// )
    ///
    /// // API 호출
    /// let user: User = try await networkClient.request(userRequest)
    /// ```
    static func makeNetworkClient(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil
    ) -> NetworkClient {
        // 1. 토큰 저장소 (외부 주입 또는 Keychain 기반 생성)
        let store = tokenStore ?? KeychainTokenStore()

        // 2. 실제 서버 토큰 갱신 서비스 생성
        let refreshService = TokenRefreshServiceImpl(baseURL: baseURL, session: session)

        // 3. NetworkClient 생성 (모든 의존성 주입)
        return NetworkClient(
            session: session,
            tokenStore: store,
            refreshService: refreshService
        )
    }

    /// 테스트 환경용 NetworkClient를 생성합니다.
    ///
    /// Mock TokenStore와 TokenRefreshService를 주입하여 테스트 가능한 NetworkClient를 생성합니다.
    ///
    /// - Parameters:
    ///   - tokenStore: Mock TokenStore (테스트용)
    ///   - refreshService: Mock TokenRefreshService (테스트용)
    ///
    /// - Returns: 테스트용으로 구성된 NetworkClient 인스턴스
    ///
    /// - Important: 실제 네트워크 호출 없이 유닛 테스트 가능
    ///
    /// ## 테스트 예시
    ///
    /// ```swift
    /// // Mock 구현
    /// actor MockTokenStore: TokenStore {
    ///     var accessToken: String?
    ///     var refreshToken: String?
    ///
    ///     func getAccessToken() async -> String? { accessToken }
    ///     func getRefreshToken() async -> String? { refreshToken }
    ///     func save(accessToken: String, refreshToken: String) async throws {
    ///         self.accessToken = accessToken
    ///         self.refreshToken = refreshToken
    ///     }
    ///     func clear() async throws {
    ///         accessToken = nil
    ///         refreshToken = nil
    ///     }
    /// }
    ///
    /// struct MockTokenRefreshService: TokenRefreshService {
    ///     func refresh(_ refreshToken: String) async throws -> TokenPair {
    ///         TokenPair(accessToken: "new_access", refreshToken: "new_refresh")
    ///     }
    /// }
    ///
    /// // 테스트 코드
    /// func testTokenRefresh() async throws {
    ///     let mockStore = MockTokenStore()
    ///     let mockRefreshService = MockTokenRefreshService()
    ///
    ///     let networkClient = AuthSystemFactory.makeTestNetworkClient(
    ///         tokenStore: mockStore,
    ///         refreshService: mockRefreshService
    ///     )
    ///
    ///     // 테스트 로직
    ///     try await mockStore.save(accessToken: "old_access", refreshToken: "old_refresh")
    ///     let newTokenPair = try await networkClient.forceRefreshToken()
    ///     XCTAssertEqual(newTokenPair.accessToken, "new_access")
    /// }
    /// ```
    static func makeTestNetworkClient(
        tokenStore: TokenStore,
        refreshService: TokenRefreshService
    ) -> NetworkClient {
        NetworkClient(
            session: .shared,
            tokenStore: tokenStore,
            refreshService: refreshService
        )
    }
}
