//
//  FormTextFieldModifier.swift
//  AppProduct
//
//  Created by 김미주 on 1/3/26.
//

import Foundation
import SwiftUI

// MARK: - AnyFormTextField

protocol AnyFormTextField: View {}

// MARK: - ViewModifier

struct FormTextFieldSecureModifier: ViewModifier {
    let isSecure: Bool

    func body(content: Content) -> some View {
        content.environment(\.formTextFieldIsSecure, isSecure)
    }
}

struct FormTextFieldDisabledModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content.environment(\.formTextFieldIsDisabled, isDisabled)
    }
}

// MARK: - AnyFormTextField Extension

extension AnyFormTextField {
    // 비밀번호 여부
    func secure(_ isSecure: Bool = true) -> some View {
        modifier(FormTextFieldSecureModifier(isSecure: isSecure))
    }

    // 비활성화 여부
    func disabled(_ isDisabled: Bool = true) -> some View {
        modifier(FormTextFieldDisabledModifier(isDisabled: isDisabled))
    }
}
