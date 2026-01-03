//
//  ChipButtonModifiers.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - AnyChipButton Protocol

/// ChipButton 전용 프로토콜
protocol AnyChipButton: View { }

// MARK: - ViewModifiers

struct ChipButtonSizeModifier: ViewModifier {
    let size: ChipButtonSize
    
    func body(content: Content) -> some View {
        content.environment(\.chipButtonSize, size)
    }
}

struct ChipButtonIsSelectedModifier: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content.environment(\.chipButtonIsSelected, isSelected)
    }
}

// MARK: - AnyChipButton Extension

extension AnyChipButton {
    
    /// 버튼 사이즈 설정
    /// - Parameter size: small, medium, large
    func buttonSize(_ size: ChipButtonSize) -> some View {
        self.modifier(ChipButtonSizeModifier(size: size))
    }
    
    func selected(_ isSelected: Bool) -> some View {
        self.modifier(ChipButtonIsSelectedModifier(isSelected: isSelected))
    }
}
