//
//  InfoBadge.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

// MARK: - InfoBadge

struct InfoBadge: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        static let backgroundOpacity: Double = 0.15
    }

    // MARK: - Property

    private let text: String
    private let textColor: Color
    private let tintColor: Color?
    private let glassVariant: GlassVariant

    enum GlassVariant: Equatable {
        case regular
        case clear
    }

    // MARK: - Initializer

    init(
        _ text: String,
        textColor: Color = .grey600,
        tintColor: Color? = nil,
        glassVariant: GlassVariant = .regular
    ) {
        self.text = text
        self.textColor = textColor
        self.tintColor = tintColor
        self.glassVariant = glassVariant
    }

    // MARK: - Body

    var body: some View {
        switch (glassVariant, tintColor) {
        case (.regular, let color?):
            badgeText.glassEffect(
                .regular.tint(color.opacity(Constants.backgroundOpacity))
            )
        case (.regular, nil):
            badgeText.glassEffect(.regular)
        case (.clear, let color?):
            badgeText.glassEffect(
                .clear.tint(color.opacity(Constants.backgroundOpacity))
            )
        case (.clear, nil):
            badgeText.glassEffect(.clear)
        }
    }

    // MARK: - View Components

    private var badgeText: some View {
        Text(text)
            .appFont(.footnote, color: textColor)
            .lineLimit(1)
            .padding(DefaultConstant.iconPadding)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: DefaultSpacing.spacing8) {
        InfoBadge("중앙대")
        InfoBadge("Leader", tintColor: .gray)
        InfoBadge("iOS", textColor: .indigo500, tintColor: .indigo)
        InfoBadge("미디어 위", glassVariant: .clear)
    }
    .padding()
}
