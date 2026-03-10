//
//  DeleteMemberOAuthUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 3/10/26.
//

import Foundation

/// 로그인 OAuth 수단 연동 해제 UseCase Protocol
protocol DeleteMemberOAuthUseCaseProtocol {
    /// OAuth 연동을 해제합니다.
    func execute(
        memberOAuthId: Int,
        googleAccessToken: String?,
        kakaoAccessToken: String?
    ) async throws
}
