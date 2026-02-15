//
//  RegisterFCMTokenUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/14/26.
//

import Foundation

/// FCM 토큰 등록 UseCase Protocol
protocol RegisterFCMTokenUseCaseProtocol {
    /// 사용자 FCM 토큰을 서버에 등록/갱신합니다.
    /// - Parameters:
    ///   - memberId: 멤버 ID
    ///   - fcmToken: FCM 토큰 문자열
    func execute(memberId: Int, fcmToken: String) async throws
}
