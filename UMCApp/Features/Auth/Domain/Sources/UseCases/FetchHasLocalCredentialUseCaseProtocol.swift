//
//  FetchHasLocalCredentialUseCaseProtocol.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

/// 로컬(이메일/비밀번호) 자격증명 보유 여부 조회 UseCase 인터페이스
public protocol FetchHasLocalCredentialUseCaseProtocol {
    /// 로그인한 회원의 로컬 비밀번호 보유 여부를 조회한다.
    /// - Returns: 비밀번호가 등록돼 있으면 `true`, 소셜로만 가입했으면 `false`
    func execute() async throws -> Bool
}
