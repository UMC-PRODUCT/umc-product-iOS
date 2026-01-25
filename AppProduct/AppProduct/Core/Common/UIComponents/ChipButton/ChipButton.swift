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
    private let trailingIcon: Bool?
    private let action: () -> Void

    @Environment(\.chipButtonSize) private var size
    @Environment(\.chipButtonStyle) private var style

    // MARK: - Initializer

    /// ChipButton 생성자
    /// - Parameters:
    ///   - title: 버튼 텍스트
    init(_ title: String, isSelected: Bool, trailingIcon: Bool? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.trailingIcon = trailingIcon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            ChipButtonContent(
                title: title,
                size: size,
                style: style,
                isSelected: isSelected,
                trailingIcon: trailingIcon
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
    let trailingIcon: Bool?
    
    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.size == rhs.size &&
        lhs.style == rhs.style &&
        lhs.isSelected == rhs.isSelected &&
        lhs.trailingIcon == rhs.trailingIcon
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            if trailingIcon != nil && trailingIcon == true {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
        }
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
            }
        }
    }
    return Demo()
}

#Preview("ChipButton(chevron)") {
    struct Demo: View {
        @State private var selected = false
        
        var body: some View {
            HStack(spacing: 8) {
                ChipButton("small", isSelected: selected, trailingIcon: true) {
                    selected.toggle()
                }
                .buttonSize(.small)
                
                ChipButton("medium", isSelected: selected, trailingIcon: true) {
                    selected.toggle()
                }
                .buttonSize(.medium)
                
                ChipButton("large", isSelected: selected, trailingIcon: true) {
                    selected.toggle()
                }
                .buttonSize(.large)
            }
        }
    }
    return Demo()
}

#Preview("ChipButton(chevron)") {
    struct Demo: View {
            @State private var selected = false

            var body: some View {
                VStack(spacing: 15) {
                    HStack(spacing: 8) {
                        ChipButton("small", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.small)
                        
                        ChipButton("medium", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.medium)
                        
                        ChipButton("large", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.large)
                    }
                }
            }
        }
        return Demo()
}

#Preview("ChipButton(chevron)") {
    struct Demo: View {
            @State private var selected = false

            var body: some View {
                VStack(spacing: 15) {
                    HStack(spacing: 8) {
                        ChipButton("small", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.small)
                        
                        ChipButton("medium", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.medium)
                        
                        ChipButton("large", isSelected: selected, trailingIcon: true) {
                            selected.toggle()
                        }
                        .buttonSize(.large)
                    }
                }
            }
        }
        return Demo()
}
