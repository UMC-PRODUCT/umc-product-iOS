//
//  LoadingViewSize.swift
//  AppProduct
//
//  Created by 이예지 on 1/4/26.
//

import SwiftUI

// MARK: - LoadingViewSize

/// LoadingView 사이즈 유형 (향후 확장용)
enum LoadingViewSize {
    case small
    case large
    
    var size: CGSize {
        switch self {
        case .small:
            return CGSize(width: 40, height: 40)
        case .large:
            return CGSize(width: 80, height: 80)
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return .app(.footnote, weight: .regular)
        case .large:
            return .app(.body, weight: .bold)
        }
    }
}
