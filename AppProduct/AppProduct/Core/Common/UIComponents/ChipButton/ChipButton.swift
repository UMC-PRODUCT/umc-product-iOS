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
    @Environment(\.chipButtonStyle) private var style

    // MARK: - Initializer

    /// ChipButton 생성자
    /// - Parameters:
    ///   - title: 버튼 텍스트
    ///   - isSelected: 선택했을 때
    ///   - action: 선택 후 액션
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
                style: style,
                isSelected: isSelected
            )
            .equatable()
        }
    }
}

// MARK: - ChipButtonContent (Presenter)

private struct ChipButtonContent: View, Equatable {
    let title: String
    let size: ChipButtonSize
    let style: ChipButtonStyle
    let isSelected: Bool

    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
            lhs.size == rhs.size &&
            lhs.style == rhs.style &&
            lhs.isSelected == rhs.isSelected
    }

    var body: some View {
        Text(title)
            .foregroundStyle(style.textColor(isSelected: isSelected))
            .font(size.font)
            .padding(.horizontal, size.horizonPadding)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(style.bgColor(isSelected: isSelected))
            )
            .glassEffect(.clear.interactive(), in: Capsule())
    }
}

// MARK: - ChipButton + AnyChipButton

extension ChipButton: AnyChipButton {}

// MARK: - Preview

#Preview("ChipButton") {
    struct Demo: View {
        @State private var selected = false

        var body: some View {
            VStack(spacing: 15) {
                HStack(spacing: 8) {
                    ChipButton("small", isSelected: selected) {
                        selected.toggle()
                    }
                    .buttonSize(.small)

                    ChipButton("medium", isSelected: selected) {
                        selected.toggle()
                    }
                    .buttonSize(.medium)

                    ChipButton("large", isSelected: selected) {
                        selected.toggle()
                    }
                    .buttonSize(.large)
                }
                .buttonSize(.large)
            }
        }
    }
    return Demo()
}
