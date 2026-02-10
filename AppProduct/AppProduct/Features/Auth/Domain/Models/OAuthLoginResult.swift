//
//  OAuthLoginResult.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// OAuth 로그인 결과
///
/// 서버 응답에 따라 기존 회원/신규 회원을 구분합니다.
/// - 기존 회원: JWT 토큰 쌍 반환 → 바로 메인 화면
/// - 신규 회원: 인증 토큰 반환 → 회원가입 플로우
enum OAuthLoginResult: Equatable, Sendable {

    // MARK: - Cases

    /// 기존 회원 - JWT 토큰 발급 완료
    case existingMember(tokenPair: TokenPair)

    /// 신규 회원 - 회원가입 필요
    case newMember(verificationToken: String)
}
