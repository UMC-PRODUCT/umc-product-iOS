//
//  AddMemberOAuthUseCaseProtocol.swift
//  AppProduct
//
//  Created by Codex on 2/15/26.
//

import Foundation

/// 로그인 OAuth 수단 추가 연동 UseCase Protocol
protocol AddMemberOAuthUseCaseProtocol {
    /// OAuth 검증 토큰으로 연동을 추가합니다.
    func execute(oAuthVerificationToken: String) async throws -> [MemberOAuth]
}
