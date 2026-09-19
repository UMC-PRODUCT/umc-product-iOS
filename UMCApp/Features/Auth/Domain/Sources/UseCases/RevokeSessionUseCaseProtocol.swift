//
//  RevokeSessionUseCaseProtocol.swift
//  AuthDomain
//
//  Created by euijjang97 on 9/19/26.
//

/// 로그아웃 직전 서버 측 세션을 해제하는 UseCase 인터페이스
public protocol RevokeSessionUseCaseProtocol {
    /// 이 기기의 푸시 설치를 비활성화하고 리프레시 토큰을 폐기한다.
    ///
    /// 로컬 토큰을 지우기 **전에** 호출해야 한다. 서버 호출이 실패해도 로컬 로그아웃은
    /// 진행돼야 하므로 에러를 던지지 않고 로그만 남긴다.
    func execute() async
}
