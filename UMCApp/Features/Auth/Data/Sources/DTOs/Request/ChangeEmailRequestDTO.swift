//
//  ChangeEmailRequestDTO.swift
//  AuthData
//
//  Created by euijjang97 on 9/19/26.
//

/// 로그인 상태에서 이메일을 변경하는 요청 DTO
///
/// `PATCH /api/v1/member/email`
public struct ChangeEmailRequestDTO: Encodable {
    /// `CHANGE_EMAIL` 목적으로 새 이메일 인증을 마치고 받은 토큰
    public let emailVerificationToken: String

    public init(emailVerificationToken: String) {
        self.emailVerificationToken = emailVerificationToken
    }
}
