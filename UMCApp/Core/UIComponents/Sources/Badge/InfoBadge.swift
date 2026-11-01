//
//  InfoBadge.swift
//  CoreUIComponents
//
//  Created by jaewon Lee on 7/15/26.
//

import CoreDesignSystem
import SwiftUI

// MARK: - InfoBadge

/// 텍스트 뱃지 컴포넌트
///

public struct InfoBadge: View, Equatable {

    // MARK: - Constants

    fileprivate enum Constants {
        static let backgroundOpacity: Double = 0.15
    }

    // MARK: - Property

    private let text: String
    private let textColor: Color
    private let tintColor: Color?


    // MARK: - Initializer

    /// - Parameters:
    ///   - text: 뱃지에 표시할 텍스트
    ///   - textColor: 텍스트 색상
    ///   - tintColor: 배경 강조 색상
    public init(
        _ text: String,
        textColor: Color = .grey600,
        tintColor: Color? = nil
    ) {
        self.text = text
        self.textColor = textColor
        self.tintColor = tintColor
    }

    // MARK: - Body

    public var body: some View {
        badgeText
            .background {
                Capsule()
                    .fill(Color.Surface.inset)
                    .overlay {
                        Capsule().fill((tintColor ?? .clear).opacity(Constants.backgroundOpacity))
                    }
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

#if DEBUG
#Preview {
    HStack(spacing: DefaultSpacing.spacing8) {
        InfoBadge("중앙대")
        InfoBadge("Leader", tintColor: .gray)
        InfoBadge("iOS", textColor: .teal500, tintColor: .indigo)
        InfoBadge("정보")
    }
    .padding()
}
#endif
