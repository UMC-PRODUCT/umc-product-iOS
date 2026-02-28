//
//  VerifyEmailCodeUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - Protocol

/// 이메일 인증코드 검증 UseCase Protocol
protocol VerifyEmailCodeUseCaseProtocol {
    /// 이메일 인증코드 검증
    /// - Parameters:
    ///   - emailVerificationId: 이메일 인증 ID
    ///   - verificationCode: 인증 코드
    /// - Returns: 이메일 인증 토큰
    func execute(
        emailVerificationId: String,
        verificationCode: String
    ) async throws -> String
}
