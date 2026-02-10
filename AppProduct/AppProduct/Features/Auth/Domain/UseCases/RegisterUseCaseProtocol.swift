//
//  RegisterUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - Protocol

/// 회원가입 UseCase Protocol
protocol RegisterUseCaseProtocol {
    /// 회원가입 실행
    /// - Parameter request: 회원가입 요청 DTO
    /// - Returns: 생성된 회원 ID
    func execute(request: RegisterRequestDTO) async throws -> Int
}
