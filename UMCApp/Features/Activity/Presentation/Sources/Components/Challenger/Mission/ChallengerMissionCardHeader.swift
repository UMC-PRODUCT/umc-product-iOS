//
//  ChallengerMissionCardHeader.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

// MARK: - Constants

fileprivate enum Constants {
    static let chevronIconSize: CGFloat = 14
}

// MARK: - ChallengerMissionCardHeader

struct ChallengerMissionCardHeader: View, Equatable {

    // MARK: - Property

    let model: MissionCardModel
    let isExpanded: Bool
    let onToggle: () -> Void

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model && lhs.isExpanded == rhs.isExpanded
    }

    // MARK: - Body

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DefaultSpacing.spacing16) {
                WeekNumberBadge(week: model.week)

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                    Text(wrappedTitle)
                        .appFont(.callout, weight: .semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !isExpanded {
                        Text(model.missionTitle)
                            .appFont(.footnote, color: .grey500)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: Constants.chevronIconSize))
                    .foregroundStyle(Color.grey400)
            }
            .frame(minHeight: DefaultConstant.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(model.week)주차, \(model.title)")
        .accessibilityValue(isExpanded ? "펼쳐짐" : "접힘")
        .accessibilityHint(isExpanded ? "학습 내용 접기" : "학습 내용 펼치기")
    }

    // MARK: - Function

    private var wrappedTitle: String {
        model.title
            .replacingOccurrences(of: " - ", with: " - \u{200B}")
            .replacingOccurrences(of: "Spring Boot", with: "Spring\u{00A0}Boot")
    }
}

fileprivate struct WeekNumberBadge: View {

    // MARK: - Property

    let week: String

    // MARK: - Body

    var body: some View {
        Text(week)
            .appFont(.title3, weight: .semibold, color: .grey600)
            .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
            .padding(DefaultConstant.iconPadding)
            .background(Color.grey100)
            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }
}

#if DEBUG
#Preview {
    ChallengerMissionCardHeader(
        model: MissionPreviewData.singleMission,
        isExpanded: false,
        onToggle: {}
    )
    .padding(DefaultConstant.defaultListPadding)
}
#endif
