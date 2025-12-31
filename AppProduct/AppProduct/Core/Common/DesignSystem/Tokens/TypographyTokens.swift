//
//  TypographyTokens.swift
//  AppProduct
//
//  Created by jaewon Lee on 2026-01-01.
//

import SwiftUI

// MARK: - AppFont

/// 앱 전체 타이포그래피 토큰
/// Figma 디자인 시스템 기반 (Pretendard 폰트)
enum AppFont {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2

    // MARK: - Size

    var size: CGFloat {
        switch self {
        case .largeTitle:  return 34
        case .title1:      return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 16
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption1:    return 12
        case .caption2:    return 11
        }
    }

    // MARK: - Line Height Multiplier

    var lineHeightMultiplier: CGFloat {
        switch self {
        case .largeTitle:  return 1.21
        case .title1:      return 1.21
        case .title2:      return 1.27
        case .title3:      return 1.25
        case .headline:    return 1.29
        case .body:        return 1.38
        case .callout:     return 1.31
        case .subheadline: return 1.33
        case .footnote:    return 1.38
        case .caption1:    return 1.33
        case .caption2:    return 1.18
        }
    }

    // MARK: - Computed Line Height

    var lineHeight: CGFloat {
        size * lineHeightMultiplier
    }

    // MARK: - Line Spacing

    var lineSpacing: CGFloat {
        lineHeight - size
    }
}

// MARK: - AppFontWeight

enum AppFontWeight {
    case regular
    case bold

    var fontName: String {
        switch self {
        case .regular: return "Pretendard-Regular"
        case .bold:    return "Pretendard-Bold"
        }
    }

    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .bold:    return .bold
        }
    }
}

// MARK: - Font Extension

extension Font {

    /// Pretendard 기반 앱 폰트
    /// - Parameters:
    ///   - style: 타이포그래피 스타일
    ///   - weight: 폰트 굵기 (기본: regular)
    /// - Returns: 설정된 Font
    static func app(_ style: AppFont, weight: AppFontWeight = .regular) -> Font {
        .custom(weight.fontName, size: style.size)
    }

    /// Pretendard 기반 커스텀 사이즈 폰트
    /// - Parameters:
    ///   - size: 폰트 사이즈
    ///   - weight: 폰트 굵기 (기본: regular)
    /// - Returns: 설정된 Font
    static func app(size: CGFloat, weight: AppFontWeight = .regular) -> Font {
        .custom(weight.fontName, size: size)
    }
}

// MARK: - View Extension

extension View {

    /// 앱 타이포그래피 스타일 적용 (lineSpacing 포함)
    /// - Parameters:
    ///   - style: 타이포그래피 스타일
    ///   - weight: 폰트 굵기 (기본: regular)
    /// - Returns: 스타일이 적용된 View
    func appFont(_ style: AppFont, weight: AppFontWeight = .regular) -> some View {
        self
            .font(.app(style, weight: weight))
            .lineSpacing(style.lineSpacing)
    }

    /// 앱 타이포그래피 스타일 적용 (색상 포함)
    /// - Parameters:
    ///   - style: 타이포그래피 스타일
    ///   - weight: 폰트 굵기 (기본: regular)
    ///   - color: 텍스트 색상
    /// - Returns: 스타일이 적용된 View
    func appFont(
        _ style: AppFont,
        weight: AppFontWeight = .regular,
        color: Color
    ) -> some View {
        self
            .font(.app(style, weight: weight))
            .lineSpacing(style.lineSpacing)
            .foregroundStyle(color)
    }
}
