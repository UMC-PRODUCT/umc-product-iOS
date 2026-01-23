//
//  ChipButtonModifiers.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - AnyChipButton Protocol

/// ChipButton 전용 프로토콜
protocol AnyChipButton: View {}

// MARK: - ViewModifiers

struct ChipButtonSizeModifier: ViewModifier {
    let size: ChipButtonSize

    func body(content: Content) -> some View {
        content.environment(\.chipButtonSize, size)
    }
}

struct ChipButtonStyleModifier: ViewModifier {
    let style: ChipButtonStyle

    func body(content: Content) -> some View {
        content.environment(\.chipButtonStyle, style)
    }
}

// MARK: - AnyChipButton Extension

extension AnyChipButton {
    /// ChipButton 사이즈 설정
    /// - Parameter size: small, medium, large
    func buttonSize(_ size: ChipButtonSize) -> some View {
        modifier(ChipButtonSizeModifier(size: size))
    }

    /// 버튼 색상 설정
    /// - Parameter style: filter, board, fame
    func buttonStyle(_ style: ChipButtonStyle) -> some View {
        modifier(ChipButtonStyleModifier(style: style))
    }
}
