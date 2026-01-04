//
//  FormTextFieldEnvironment.swift
//  AppProduct
//
//  Created by 김미주 on 1/3/26.
//

import Foundation
import SwiftUI

// MARK: - Environment Keys

struct FormTextFieldIsDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct FormTextFieldIsFocusedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var formTextFieldIsDisabled: Bool {
        get { self[FormTextFieldIsDisabledKey.self] }
        set { self[FormTextFieldIsDisabledKey.self] = newValue }
    }

    var formTextFieldIsFocused: Bool {
        get { self[FormTextFieldIsFocusedKey.self] }
        set { self[FormTextFieldIsFocusedKey.self] = newValue }
    }
}
