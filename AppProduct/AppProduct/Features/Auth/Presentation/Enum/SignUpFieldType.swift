//
//  SignUpFieldType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import SwiftUI
import UIKit

/// 회원가입 폼 필드 타입 정의
///
/// SignUpView에서 사용되는 입력 필드의 종류와 각 필드별 설정을 관리합니다.
/// 각 케이스는 제목, 플레이스홀더, 컴포넌트 타입 등의 정보를 제공합니다.
enum SignUpFieldType: Hashable, CaseIterable {
    /// 실명 입력 필드
    case name

    /// 닉네임 입력 필드
    case nickname

    /// 이메일 입력 및 인증 필드
    case email

    /// 학교 선택 피커 필드
    case univ

    /// 필드의 UI 컴포넌트 타입
    enum FieldType {
        /// 일반 텍스트 필드 (FormTextField)
        case text

        /// 이메일 인증 필드 (FormEmailField)
        case email

        /// 선택 피커 (FormPickerField)
        case picker
    }

    /// 필드에 사용할 UI 컴포넌트 타입
    var type: FieldType {
        switch self {
        case .name, .nickname: return .text
        case .email: return .email
        case .univ: return .picker
        }
    }

    /// 필드 상단에 표시될 제목
    var title: String {
        switch self {
        case .name: return "이름"
        case .nickname: return "닉네임"
        case .email: return "이메일"
        case .univ: return "학교"
        }
    }

    /// 필드의 플레이스홀더 텍스트
    var placeholder: String {
        switch self {
        case .name: return "실명을 입력하세요"
        case .nickname: return "닉네임을 입력하세요"
        case .email: return "example@univ.ac.kr"
        case .univ: return "학교를 선택하세요"
        }
    }

    /// 필수 입력 여부 (모든 필드 필수)
    var isRequired: Bool { true }

    /// 필드별 버튼 타이틀 (이메일 필드만 인증 요청 버튼 제공)
    var buttonTitle: String? {
        self == .email ? "인증 요청" : nil
    }

    /// 필드별 키보드 타입
    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        default:
            return .default
        }
    }
}
