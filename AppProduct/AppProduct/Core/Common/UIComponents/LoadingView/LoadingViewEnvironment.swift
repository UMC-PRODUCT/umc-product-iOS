//
//  LoadingViewEnvironment.swift
//  AppProduct
//
//  Created by 이예지 on 1/4/26.
//

import SwiftUI

// MARK: - Environment Keys

struct LoadingViewSizeKey: EnvironmentKey {
    static let defaultValue: LoadingViewSize = .large
}

struct LoadingViewIsPresentedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

struct LoadingViewMessageKey: EnvironmentKey {
    static let defaultValue: String = "Loading..."
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    var loadingViewSize: LoadingViewSize {
        get { self[LoadingViewSizeKey.self] }
        set { self[LoadingViewSizeKey.self] = newValue }
    }
    
    var loadingViewIsPresented: Bool {
        get { self[LoadingViewIsPresentedKey.self] }
        set { self[LoadingViewIsPresentedKey.self] = newValue }
    }
    
    var loadingViewMessage: String {
        get { self[LoadingViewMessageKey.self] }
        set { self[LoadingViewMessageKey.self] = newValue }
    }
}
