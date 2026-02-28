//
//  ChipButtonEnvironment.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - Environment Keys

struct ChipButtonSizeKey: EnvironmentKey {
    static let defaultValue: ChipButtonSize = .medium
}

struct ChipButtonStyleKey: EnvironmentKey {
    static let defaultValue: ChipButtonStyle = .filter
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var chipButtonSize: ChipButtonSize {
        get { self[ChipButtonSizeKey.self] }
        set { self[ChipButtonSizeKey.self] = newValue }
    }
}

extension EnvironmentValues {
    var chipButtonStyle: ChipButtonStyle {
        get { self[ChipButtonStyleKey.self] }
        set { self[ChipButtonStyleKey.self] = newValue }
    }
}
