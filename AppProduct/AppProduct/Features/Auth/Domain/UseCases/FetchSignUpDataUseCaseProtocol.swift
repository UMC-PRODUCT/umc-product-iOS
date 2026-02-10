//
//  FetchSignUpDataUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

// MARK: - Protocol

/// 회원가입에 필요한 데이터(학교, 약관) 조회 UseCase Protocol
protocol FetchSignUpDataUseCaseProtocol {
    /// 학교 목록 조회
    /// - Returns: 학교 목록
    func fetchSchools() async throws -> [School]

    /// 약관 조회
    /// - Parameter termsType: 약관 종류
    /// - Returns: 약관 정보
    func fetchTerms(termsType: String) async throws -> Terms
}
