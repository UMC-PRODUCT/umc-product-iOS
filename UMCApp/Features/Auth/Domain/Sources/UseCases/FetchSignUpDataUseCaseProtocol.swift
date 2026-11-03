//
//  FetchSignUpDataUseCaseProtocol.swift
//  AuthDomain
//
//  Created by euijjang97 on 7/9/26.
//

/// 회원가입 화면에 필요한 학교/약관 데이터 조회 UseCase 인터페이스
public protocol FetchSignUpDataUseCaseProtocol {
    /// 해당 학교에서 닉네임을 사용할 수 있는지 확인한다.
    func checkNicknameAvailability(schoolId: String, nickname: String) async throws -> Bool

    /// 학교 목록을 조회한다.
    func fetchSchools() async throws -> [School]

    /// 특정 종류의 약관을 조회한다.
    /// - Parameter type: 약관 종류
    func fetchTerms(type: TermsType) async throws -> Terms
}
