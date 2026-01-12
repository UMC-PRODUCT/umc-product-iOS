//
//  SignUpViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation

/// 회원가입 뷰모델
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
    
    
}
