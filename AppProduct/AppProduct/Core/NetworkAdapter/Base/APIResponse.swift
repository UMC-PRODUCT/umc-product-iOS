//
//  APIResponse.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

/// 서버 공통 응답 DTO
///
/// Spring 백엔드의 `ApiResponse<T>` 형식과 매핑됩니다.
///
/// ## 서버 응답 형식
/// ```json
/// {
///   "success": true,
///   "code": "200",
///   "message": "성공",
///   "result": { ... }
/// }
/// ```
///
/// ## 사용 예시
/// ```swift
/// let response = try JSONDecoder().decode(
///     APIResponse<UserDTO>.self,
///     from: data
/// )
///
/// guard response.isSuccess, let user = response.result else {
///     throw RepositoryError.serverError(
///         code: response.code,
///         message: response.message
///     )
/// }
/// ```
struct APIResponse<T: Codable>: Codable {

    // MARK: - Property

    /// 요청 성공 여부
    let isSuccess: Bool

    /// 응답 코드 (e.g., "200", "AUTH001")
    let code: String?

    /// 응답 메시지 (e.g., "성공", "인증에 실패했습니다")
    let message: String?

    /// 응답 데이터 (성공 시에만 존재)
    let result: T?

    // MARK: - CodingKeys

    /// Spring `@JsonProperty("success")` 매핑
    private enum CodingKeys: String, CodingKey {
        case isSuccess = "success"
        case code
        case message
        case result
    }
}

// MARK: - Convenience

extension APIResponse {

    /// 성공 응답인지 확인하고 result를 반환
    ///
    /// - Throws: `RepositoryError.serverError` (실패 시)
    /// - Returns: result 값
    func unwrap() throws -> T {
        guard isSuccess, let result else {
            throw RepositoryError.serverError(code: code, message: message)
        }
        return result
    }

    /// 에러 메시지 (실패 시 사용)
    var errorMessage: String {
        message ?? "알 수 없는 오류가 발생했습니다"
    }

    /// 에러 코드 (실패 시 사용)
    var errorCode: String {
        code ?? "UNKNOWN"
    }
}

// MARK: - Empty Result

/// 결과 데이터가 없는 API 응답용 (DELETE 등)
struct EmptyResult: Codable, Sendable, Equatable {}
