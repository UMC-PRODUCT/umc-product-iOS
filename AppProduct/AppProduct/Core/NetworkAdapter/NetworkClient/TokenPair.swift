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

// MARK: - NetworkError

/// 네트워크 계층에서 발생하는 모든 에러를 정의하는 열거형입니다.
///
/// NetworkClient, TokenStore, TokenRefreshService에서 발생 가능한 에러를 타입 안전하게 표현합니다.
///
/// - Important:
///   - **Sendable**: Actor 간 안전한 에러 전파
///   - **LocalizedError**: 사용자 친화적 에러 메시지 제공
///
/// - Usage:
/// ```swift
/// do {
///     let data = try await networkClient.request(urlRequest)
/// } catch NetworkError.unauthorized {
///     // 로그아웃 처리
/// } catch NetworkError.tokenRefreshFailed {
///     // 재로그인 유도
/// } catch NetworkError.requestFailed(let statusCode, _) {
///     // 서버 에러 처리
/// }
/// ```
enum NetworkError: Error, Sendable {
    // MARK: - Cases

    /// 인증이 필요한 요청에 토큰이 없음 (401 Unauthorized)
    ///
    /// - 발생 시점: 로그인하지 않은 상태에서 인증 필요 API 호출
    /// - 해결 방법: 로그인 화면으로 이동
    case unauthorized

    /// 리프레시 토큰을 사용한 토큰 갱신 실패
    ///
    /// - Parameter underlying: 갱신 실패 원인 에러 (네트워크 에러, 서버 에러 등)
    ///
    /// - 발생 시점:
    ///   - 리프레시 토큰 만료
    ///   - 서버 토큰 갱신 API 호출 실패
    ///   - 네트워크 연결 끊김
    ///
    /// - 해결 방법: 재로그인 필요
    case tokenRefreshFailed(underlying: Error?)

    /// 저장소에 리프레시 토큰이 없음
    ///
    /// - 발생 시점:
    ///   - 로그아웃 상태
    ///   - Keychain 데이터 손실
    ///
    /// - 해결 방법: 로그인 화면으로 이동
    case noRefreshToken

    /// API 요청 실패 (2xx 이외의 상태 코드)
    ///
    /// - Parameters:
    ///   - statusCode: HTTP 상태 코드 (400, 403, 404, 500 등)
    ///   - data: 서버 응답 데이터 (에러 메시지 파싱 가능)
    ///
    /// - 발생 시점:
    ///   - 잘못된 요청 (400 Bad Request)
    ///   - 권한 없음 (403 Forbidden)
    ///   - 리소스 없음 (404 Not Found)
    ///   - 서버 에러 (500 Internal Server Error)
    ///
    /// - 해결 방법: 상태 코드별 적절한 에러 처리
    case requestFailed(statusCode: Int, data: Data?)

    /// 서버 응답이 HTTPURLResponse가 아님
    ///
    /// - 발생 시점: 네트워크 설정 오류, 프록시 에러 등
    /// - 해결 방법: 네트워크 연결 확인
    case invalidResponse

    /// 토큰 갱신 재시도 횟수 초과
    ///
    /// - 발생 시점: 401 에러 발생 후 재시도 횟수(기본 1회) 초과
    /// - 해결 방법: 재로그인 필요
    case maxRetryExceeded
}

// MARK: - NetworkError + LocalizedError

extension NetworkError: LocalizedError {
    /// 사용자에게 표시할 에러 메시지를 반환합니다.
    ///
    /// - Returns: 에러 유형에 맞는 한글 에러 메시지
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
