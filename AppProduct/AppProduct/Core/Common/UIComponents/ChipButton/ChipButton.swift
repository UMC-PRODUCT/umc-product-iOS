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
    private let leadingIcon: String?
    private let trailingIcon: Bool?
    private let action: (() -> Void)?

    @Environment(\.chipButtonSize) private var size
    @Environment(\.chipButtonStyle) private var style

    // MARK: - Initializer

    /// ChipButton 생성자
    /// - Parameters:
    ///   - title: 버튼 텍스트
    ///   - isSelected: 선택 상태
    ///   - trailingIcon: 트레일링 아이콘 표시 여부
    ///   - action: 탭 액션 (nil이면 읽기 전용 태그로 동작)
    init(
        _ title: String,
        isSelected: Bool,
        leadingIcon: String? = nil,
        trailingIcon: Bool? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.isSelected = isSelected
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        if let action = action {
            Button(action: action) {
                ChipButtonContent(
                    title: title,
                    size: size,
                    style: style,
                    isSelected: isSelected,
                    leadingIcon: leadingIcon,
                    trailingIcon: trailingIcon,
                    isInteractive: true
                )
                .equatable()
            }
        } else {
            ChipButtonContent(
                title: title,
                size: size,
                style: style,
                isSelected: isSelected,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon,
                isInteractive: false
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
    let leadingIcon: String?
    let trailingIcon: Bool?
    let isInteractive: Bool
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let chevronSize: CGFloat = 10
        static let btnVerticalPadding: CGFloat = 8
    }
    
    static func == (lhs: ChipButtonContent, rhs: ChipButtonContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.size == rhs.size &&
        lhs.style == rhs.style &&
        lhs.isSelected == rhs.isSelected &&
        lhs.leadingIcon == rhs.leadingIcon &&
        lhs.trailingIcon == rhs.trailingIcon &&
        lhs.isInteractive == rhs.isInteractive
    }

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Text(title)
            if trailingIcon == true {
                Image(systemName: "chevron.down")
                    .font(.system(size: Constants.chevronSize))
            }
        }
        .foregroundStyle(style.textColor(isSelected: isSelected))
        .font(size.font)
        .padding(.horizontal, size.horizonPadding)
        .padding(.vertical, Constants.btnVerticalPadding)
        .background(
            Capsule()
                .fill(style.bgColor(isSelected: isSelected))
        )
        .glassEffect(
            isInteractive ? .clear.interactive() : .identity,
            in: Capsule()
        )
    }
}

// MARK: - ChipButton + AnyChipButton

extension ChipButton: AnyChipButton {}
