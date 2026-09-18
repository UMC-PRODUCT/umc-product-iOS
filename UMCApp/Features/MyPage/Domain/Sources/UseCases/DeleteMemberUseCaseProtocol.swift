//
//  DeleteMemberUseCaseProtocol.swift
//  MyPageDomain
//
//  Created by euijjang97 on 5/10/26.
//

import Foundation

/// 회원 탈퇴 UseCase Protocol
///
/// 모든 데이터를 지우고 회원 탈퇴를 진행합니다.
public protocol DeleteMemberUseCaseProtocol {
    /// 회원 탈퇴를 수행합니다.
    ///
    /// 전달한 access token의 Provider는 서버가 앱 연결도 함께 해제(revoke)합니다.
    /// 토큰이 없는 Provider는 revoke만 건너뛰고 탈퇴는 그대로 진행됩니다.
    /// - Parameters:
    ///   - googleAccessToken: Google 연동 해제용 액세스 토큰
    ///   - kakaoAccessToken: Kakao 연동 해제용 액세스 토큰
    func execute(googleAccessToken: String?, kakaoAccessToken: String?) async throws
}
