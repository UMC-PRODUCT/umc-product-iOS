//
//  LogoutRequestDTO.swift
//  AuthData
//
//  Created by euijjang97 on 9/19/26.
//

/// 로그아웃(리프레시 토큰 폐기) 요청 DTO
///
/// `POST /api/v1/auth/logout`
public struct LogoutRequestDTO: Encodable {
    /// 서버 allow-list에서 제거할 리프레시 토큰
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
