//
//  ChangeEmailUseCaseProtocol.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

/// 이메일 변경 UseCase 인터페이스
public protocol ChangeEmailUseCaseProtocol {
    /// 새 이메일 인증 토큰으로 이메일을 변경하고, 캐시된 내 프로필을 무효화한다.
    /// - Parameter emailVerificationToken: `CHANGE_EMAIL` 목적 인증 완료 토큰
    func execute(emailVerificationToken: String) async throws
}
