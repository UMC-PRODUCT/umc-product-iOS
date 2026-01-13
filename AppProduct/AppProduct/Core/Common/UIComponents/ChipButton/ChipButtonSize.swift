//
//  ChipButtonSize.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - ChipButtonSize

/// ChipButton 사이즈 유형
enum ChipButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:
            return 25
        case .medium:
            return 29
        case .large:
            return 32
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return .app(.caption2, weight: .bold)
        case .medium:
            return .app(.caption1, weight: .bold)
        case .large:
            return .app(.footnote, weight: .bold)
        }
    }
}
