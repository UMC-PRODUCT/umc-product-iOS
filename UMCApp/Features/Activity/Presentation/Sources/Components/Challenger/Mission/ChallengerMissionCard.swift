//
//  ChallengerMissionCard.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

fileprivate enum Constants {
    static let railWidth: CGFloat = 2
    static let cardBorderWidth: CGFloat = 1
    static let rowStackSpacing: CGFloat = 0
}

struct ChallengerMissionCard: View, Equatable {

    // MARK: - Property

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let model: MissionCardModel
    let isFirst: Bool
    let isLast: Bool

    private var nodeColumnWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? DefaultSpacing.spacing16 : DefaultConstant.iconSize
    }

    private var nodeDiameter: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? DefaultSpacing.spacing12 : DefaultConstant.iconSize
    }

    private var nodeCenter: CGFloat {
        DefaultSpacing.spacing16 + nodeDiameter / 2
    }

    private var description: String {
        model.missionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model
            && lhs.isFirst == rhs.isFirst
            && lhs.isLast == rhs.isLast
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            ChallengerMissionCardHeader(model: model)

            if !description.isEmpty {
                ChallengerMissionCardContent(description: description)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .strokeBorder(Color.grey200, lineWidth: Constants.cardBorderWidth)
        }
        .accessibilityElement(children: .combine)
        .padding(.leading, nodeColumnWidth + DefaultSpacing.spacing12)
        .padding(.bottom, isLast ? 0 : DefaultSpacing.spacing16)
        .background(alignment: .leading) {
            rail
                .accessibilityHidden(true)
        }
        .overlay(alignment: .topLeading) {
            node
                .frame(width: nodeColumnWidth)
                .padding(.top, DefaultSpacing.spacing16)
                .accessibilityHidden(true)
        }
    }

    // MARK: - View Components

    private var rail: some View {
        VStack(spacing: Constants.rowStackSpacing) {
            Rectangle()
                .fill(Color.grey300)
                .frame(width: Constants.railWidth, height: nodeCenter)
                .opacity(isFirst ? 0 : 1)

            Rectangle()
                .fill(Color.grey300)
                .frame(width: Constants.railWidth)
                .frame(maxHeight: .infinity)
                .opacity(isLast ? 0 : 1)
        }
        .frame(width: nodeColumnWidth)
    }

    private var node: some View {
        Circle()
            .fill(Color.grey000)
            .overlay {
                Circle()
                    .strokeBorder(Color.grey200, lineWidth: Constants.cardBorderWidth)
            }
            .overlay {
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(model.week)
                        .appFont(.footnote, weight: .semibold, color: .grey700)
                }
            }
            .frame(width: nodeDiameter, height: nodeDiameter)
    }
}

#if DEBUG
#Preview {
    ChallengerCurriculumView(
        curriculumModel: MissionPreviewData.sampleHeader,
        missions: MissionPreviewData.sampleMissions
    )
}
#endif
