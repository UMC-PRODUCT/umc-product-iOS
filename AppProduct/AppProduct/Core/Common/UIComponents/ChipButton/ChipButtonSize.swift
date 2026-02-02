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
    
    var horizonPadding: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 16
        case .large:
            return 16
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return .app(.footnoteEmphasis, weight: .semibold)
        case .medium:
            return .app(.subheadlineEmphasis, weight: .semibold)
        case .large:
            return .app(.calloutEmphasis, weight: .semibold)
        }
    }
}
