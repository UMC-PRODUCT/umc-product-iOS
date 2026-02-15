//
//  RegisterExistingChallengerUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// 기존 챌린저 인증 코드 등록 UseCase Protocol
protocol RegisterExistingChallengerUseCaseProtocol {
    /// 기존 챌린저 인증 코드를 서버에 등록합니다.
    /// - Parameter code: 운영진 발급 6자리 코드
    func execute(code: String) async throws
}
