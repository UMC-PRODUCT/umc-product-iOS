//
//  SendEmailVerificationUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - Protocol

/// 이메일 인증 발송 UseCase Protocol
protocol SendEmailVerificationUseCaseProtocol {
    /// 이메일 인증 발송
    /// - Parameter email: 인증할 이메일 주소
    /// - Returns: 이메일 인증 ID
    func execute(email: String) async throws -> String
}
