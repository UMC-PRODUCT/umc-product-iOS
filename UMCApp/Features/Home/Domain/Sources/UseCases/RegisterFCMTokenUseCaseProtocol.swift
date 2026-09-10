//
//  RegisterFCMTokenUseCaseProtocol.swift
//  HomeDomain
//
//  Created by euijjang97 on 8/6/26.
//

import Foundation

/// FCM 토큰 등록 UseCase 프로토콜.
public protocol RegisterFCMTokenUseCaseProtocol {

    /// 사용자 FCM 토큰을 서버에 등록/갱신한다.
    /// - Parameter fcmToken: Firebase Cloud Messaging 토큰
    func execute(fcmToken: String) async throws
}
