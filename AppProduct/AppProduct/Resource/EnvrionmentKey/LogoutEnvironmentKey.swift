//
//  LogoutEnvironmentKey.swift
//  AppProduct
//

import SwiftUI

struct LogoutEnvironmentKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var logout: () -> Void {
        get { self[LogoutEnvironmentKey.self] }
        set { self[LogoutEnvironmentKey.self] = newValue }
    }
}
