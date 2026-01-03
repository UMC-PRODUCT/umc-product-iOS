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

struct ChipButtonIsSelectedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var chipButtonSize: ChipButtonSize {
        get { self[ChipButtonSizeKey.self] }
        set { self[ChipButtonSizeKey.self] = newValue }
    }
    
    var chipButtonIsSelected: Bool {
        get { self[ChipButtonIsSelectedKey.self] }
        set { self[ChipButtonIsSelectedKey.self] = newValue }
    }
}
