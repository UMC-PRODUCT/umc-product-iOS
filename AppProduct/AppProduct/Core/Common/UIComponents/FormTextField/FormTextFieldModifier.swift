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

struct FormTextFieldDisabledModifier: ViewModifier {
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content.environment(\.formTextFieldIsDisabled, isDisabled)
    }
}

// MARK: - AnyFormTextField Extension

extension AnyFormTextField {
    // 비활성화 여부
    func formDisabled(_ isDisabled: Bool = true) -> some View {
        modifier(FormTextFieldDisabledModifier(isDisabled: isDisabled))
    }
}
