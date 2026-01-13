//
//  SignUpViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation


@Observable
class SignUpViewModel {
    var name: String = ""
    var nickname: String = ""
    var email: String = ""
    var emailCode: String = ""
    var selectedUniv: String?
    var univList: [String] = [
        "서울대학교",
        "연세대학교",
        "고려대학교",
        "상균관대학교"
    ]
    var isEmailVerified: Bool = false
    
    var isFormValid: Bool {
        !name.isEmpty &&
        !nickname.isEmpty &&
        !email.isEmpty &&
        selectedUniv != nil &&
        isEmailVerified
    }

    // MARK: - Methods
    /// 이메일 인증번호 요청
    func requestEmailVerification() async throws {
        // TODO: 실제 API 엔드포인트 호출
    }

    /// 이메일 인증번호 검증
    func verifyEmailCode(_ code: String) async throws {
        // TODO: 실제 API 엔드포인트 호출

        self.emailCode = code
        self.isEmailVerified = true
    }
}
