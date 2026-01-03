//
//  ChipButton.swift
//  AppProduct
//
//  Created by 이예지 on 1/3/26.
//

import SwiftUI

// MARK: - ChipButton

struct ChipButton: View {
    
    // MARK: - Properties
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void
    
    @Environment(\.chipButtonSize) private var size
    
    // MARK: - Initializer
    
    /// ChipButton 생성자
    /// - Parameters:
    ///   - title: 버튼 텍스트
    ///   - icon: 버튼 체크 아이콘
    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
                ChipButtonContent(
                    title: title,
                    size: size,
                    isSelected: isSelected
                )
                .equatable()
            }
        .buttonStyle(.plain)
    }
}

// MARK: - MainButtonContent (Presenter)

private struct ChipButtonContent: View, Equatable {
    let title: String
    let size: ChipButtonSize
    let isSelected: Bool
    
    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.size == rhs.size &&
        lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        Text(title)
            .foregroundStyle(Color.neutral900)
            .font(size.font)
            .padding(.horizontal, 8)
            .frame(height: size.height)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primary100 : Color.primary400)
            )
    }
}

// MARK: - ChipButton + AnyChipButton

extension ChipButton: AnyChipButton { }

// MARK: - Preview

#Preview("ChipButton with LiquidGlass") {
    VStack(spacing: 15) {
        HStack(spacing: 8) {
            ChipButton("Small", isSelected: false) { }
                .buttonSize(.small)
            ChipButton("Medium", isSelected: true) { }
                .buttonSize(.medium)
            ChipButton("Large", isSelected: true) { }
                .buttonSize(.large)
        }
    }
}
