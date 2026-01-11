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

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var chipButtonSize: ChipButtonSize {
        get { self[ChipButtonSizeKey.self] }
        set { self[ChipButtonSizeKey.self] = newValue }
    }
}
