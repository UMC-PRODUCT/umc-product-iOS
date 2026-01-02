//
//  MainButtonSize.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/02/26.
//

import SwiftUI

// MARK: - MainButtonSize

/// MainButton 사이즈 유형 (향후 확장용)
enum MainButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var font: Font {
        switch self {
        case .small: return .app(.footnote, weight: .bold)
        case .medium: return .app(.body, weight: .bold)
        case .large: return .app(.headline, weight: .bold)
        }
    }
}
