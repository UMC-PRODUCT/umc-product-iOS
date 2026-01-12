//
//  SignUpFieldType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI


enum SignUpFieldType: CaseIterable {
    case name
    case nickname
    case email
    case univ
    
    enum FieldType {
        case text
        case email
        case picker
    }
    
    var type: FieldType {
        switch self {
        case .name, .nickname: return .text
        case .email: return .email
        case .univ: return .picker
        }
    }
    
    var title: String {
        switch self {
        case .name: return "이름"
        case .nickname: return "닉네임"
        case .email: return "이메일"
        case .univ: return "학교"
        }
    }
    
    var placeholder: String {
        switch self {
        case .name: return "실명을 입력하세요"
        case .nickname: return "활동할 닉네임을 입력하세요"
        case .email: return "example@univ.ac.kr"
        case .univ: return "학교를 선택하세요"
        }
    }
    
    var isRequired: Bool { true }
    
    var buttonTitle: String? {
        self == .email ? "인증 요청" : nil
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        default:
            return .default
        }
    }
}
