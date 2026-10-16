//
//  ChallengerCurriculumHeaderCard.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

fileprivate enum Constants {
    static let cardBorderWidth: CGFloat = 1
    static let headerIconTintOpacity: Double = 0.12
    static let headerBorderTintOpacity: Double = 0.35
}

struct ChallengerCurriculumHeaderCard: View, Equatable {

    // MARK: - Property

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: CurriculumHeaderModel

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "book.fill")
                    .font(.app(.title3))
                    .foregroundStyle(model.partColor)
                    .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
                    .background {
                        RoundedRectangle(
                            cornerRadius: DefaultConstant.cornerRadius,
                            style: .continuous
                        )
                        .fill(Color.grey000)
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: DefaultConstant.cornerRadius,
                                style: .continuous
                            )
                            .fill(model.partColor.opacity(Constants.headerIconTintOpacity))
                        }
                    }
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(model.partName)
                    .appFont(.caption1, weight: .medium, color: .grey700)

                Text(model.curriculumTitle)
                    .appFont(.title2, weight: .semibold, color: .grey900)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(
            Color.grey000,
            in: RoundedRectangle(
                cornerRadius: DefaultConstant.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: DefaultConstant.cornerRadius,
                style: .continuous
            )
            .strokeBorder(
                model.partColor.opacity(Constants.headerBorderTintOpacity),
                lineWidth: Constants.cardBorderWidth
            )
        }
    }
}

#if DEBUG
#Preview {
    ChallengerCurriculumHeaderCard(model: MissionPreviewData.sampleHeader)
        .padding()
        .background(Color.grey100)
}
#endif
