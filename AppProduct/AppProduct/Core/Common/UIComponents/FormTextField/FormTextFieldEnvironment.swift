//
//  FormTextFieldEnvironment.swift
//  AppProduct
//
//  Created by 김미주 on 1/3/26.
//

import Foundation
import SwiftUI

// MARK: - Environment Keys

struct FormTextFieldIsSecureKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct FormTextFieldIsDisabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var formTextFieldIsSecure: Bool {
        get { self[FormTextFieldIsSecureKey.self] }
        set { self[FormTextFieldIsSecureKey.self] = newValue }
    }

    var formTextFieldIsDisabled: Bool {
        get { self[FormTextFieldIsDisabledKey.self] }
        set { self[FormTextFieldIsDisabledKey.self] = newValue }
    }
}
