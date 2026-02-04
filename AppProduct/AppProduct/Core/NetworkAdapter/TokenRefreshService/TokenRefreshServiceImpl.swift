//
//  TokenRefreshServiceImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

/// TokenRefreshService 프로토콜의 실제 구현체입니다.
///
/// 서버의 `/auth/reissue` 엔드포인트를 호출하여 리프레시 토큰으로 새로운 토큰 쌍을 발급받습니다.
///
/// - Important:
///   - **NetworkClient와 독립적**: NetworkClient를 사용하지 않음 (무한 루프 방지)
///   - **CommonDTO 사용**: 서버의 공통 응답 포맷 사용
///   - **Bearer 인증**: 리프레시 토큰을 Authorization 헤더에 전송
///
/// - Usage:
/// ```swift
/// let refreshService = TokenRefreshServiceImpl(
///     baseURL: URL(string: "https://api.example.com")!
/// )
///
/// do {
///     let newTokenPair = try await refreshService.refresh(oldRefreshToken)
///     print("새 액세스 토큰: \(newTokenPair.accessToken)")
/// } catch TokenRefreshError.serverError(let statusCode) {
///     print("서버 에러: \(statusCode)")
/// }
/// ```
struct TokenRefreshServiceImpl: TokenRefreshService {
    // MARK: - Property

    /// API 서버 기본 URL
    ///
    /// - Note: `/auth/reissue` 경로가 추가됩니다.
    private let baseURL: URL

    /// URLSession 인스턴스 (네트워크 요청 실행)
    ///
    /// - Note: 테스트 시 커스텀 URLSession 주입 가능
    private let session: URLSession

    /// JSON 디코더
    ///
    /// - Note: 서버 응답을 TokenPair로 파싱
    private let decoder: JSONDecoder

    // MARK: - Initializer

    /// TokenRefreshServiceImpl 초기화
    ///
    /// - Parameters:
    ///   - baseURL: API 서버 기본 URL (필수)
    ///   - session: URLSession (기본값: .shared)
    ///   - decoder: JSONDecoder (기본값: JSONDecoder())
    ///
    /// - Important: DIContainer에서 싱글톤으로 관리됩니다.
    nonisolated init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    // MARK: - TokenRefreshService

    /// 리프레시 토큰으로 새로운 토큰 쌍을 발급받습니다.
    ///
    /// - Parameter refreshToken: 현재 저장된 리프레시 토큰
    ///
    /// - Returns: 새로 발급받은 액세스 토큰과 리프레시 토큰 쌍
    ///
    /// - Throws:
    ///   - `TokenRefreshError.invalidResponse`: HTTPURLResponse 형변환 실패
    ///   - `TokenRefreshError.serverError`: 서버 에러 (2xx 이외)
    ///   - `TokenRefreshError.refreshFailed`: 서버가 실패 응답 반환
    ///
    /// ## 요청 형식
    ///
    /// ```
    /// POST /auth/reissue
    /// Content-Type: application/json
    /// Authorization: Bearer {refreshToken}
    /// ```
    ///
    /// ## 응답 형식
    ///
    /// ```json
    /// {
    ///   "isSuccess": true,
    ///   "code": "200",
    ///   "message": "성공",
    ///   "result": {
    ///     "accessToken": "eyJhbGc...",
    ///     "refreshToken": "dGhpcyBp..."
    ///   }
    /// }
    /// ```
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        // 1. URL 생성
        let url = baseURL.appending(path: "auth/reissue")

        // 2. URLRequest 구성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        // 3. 네트워크 요청 실행
        let (data, response) = try await session.data(for: request)

        // 4. HTTPURLResponse 형변환
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }

        // 5. 상태 코드 확인 (2xx 성공)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TokenRefreshError.serverError(statusCode: httpResponse.statusCode)
        }

        // 6. 응답 디코딩 (APIResponse 사용)
        let tokenResponse = try decoder.decode(APIResponse<TokenResult>.self, from: data)

        // 7. 성공 여부 확인
        guard tokenResponse.isSuccess, let result = tokenResponse.result else {
            throw TokenRefreshError.refreshFailed(message: tokenResponse.message)
        }

        // 8. TokenPair 생성
        return TokenPair(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken
        )
    }
}

// MARK: - TokenResult

/// 토큰 갱신 API 응답의 result 필드를 파싱하는 내부 모델입니다.
///
/// - Note: APIResponse<TokenResult> 형식으로 래핑됩니다.
private struct TokenResult: Codable, Sendable {
    /// 새로 발급받은 액세스 토큰
    let accessToken: String

    /// 새로 발급받은 리프레시 토큰
    let refreshToken: String
}

// MARK: - TokenRefreshError

/// 토큰 갱신 과정에서 발생하는 에러를 정의하는 열거형입니다.
///
/// - Important: NetworkClient는 이 에러를 `NetworkError.tokenRefreshFailed`로 래핑합니다.
public enum TokenRefreshError: Error, LocalizedError {
    // MARK: - Cases

    /// HTTPURLResponse 형변환 실패
    ///
    /// - 발생 시점: 네트워크 설정 오류, 프록시 에러 등
    case invalidResponse

    /// 서버 에러 (2xx 이외의 상태 코드)
    ///
    /// - Parameter statusCode: HTTP 상태 코드
    ///
    /// - 발생 시점:
    ///   - 401: 리프레시 토큰 만료 또는 유효하지 않음
    ///   - 500: 서버 내부 에러
    case serverError(statusCode: Int)

    /// 서버가 실패 응답 반환 (isSuccess: false)
    ///
    /// - Parameter message: 서버에서 전달한 에러 메시지
    ///
    /// - 발생 시점: 서버 비즈니스 로직 검증 실패
    case refreshFailed(message: String?)

    // MARK: - LocalizedError

    /// 사용자에게 표시할 에러 메시지를 반환합니다.
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
