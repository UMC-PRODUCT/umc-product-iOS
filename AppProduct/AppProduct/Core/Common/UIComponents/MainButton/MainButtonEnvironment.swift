//
//  MainButtonEnvironment.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/02/26.
//

import SwiftUI

// MARK: - Environment Keys

struct MainButtonSizeKey: EnvironmentKey {
    static let defaultValue: MainButtonSize = .medium
}

struct MainButtonIsLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var mainButtonSize: MainButtonSize {
        get { self[MainButtonSizeKey.self] }
        set { self[MainButtonSizeKey.self] = newValue }
    }

    var mainButtonIsLoading: Bool {
        get { self[MainButtonIsLoadingKey.self] }
        set { self[MainButtonIsLoadingKey.self] = newValue }
    }
}
