//
//  DIEnvrionmentKey.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import Foundation
import SwiftUI

struct DIEnvironmentKey: EnvironmentKey {
    static let defaultValue: DIContainer = .init()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIEnvironmentKey.self] }
        set { self[DIEnvironmentKey.self] = newValue }
    }
}
