//
//  MissionCardHeader.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCardHeader

/// 미션 카드 헤더 (주차 태그, 플랫폼 태그, 제목, 상태 뱃지, 펼치기 버튼)
struct MissionCardHeader: View, Equatable {

    // MARK: - Property

    private let model: MissionCardModel
    private let isExpanded: Bool
    private let onToggle: () -> Void

    // MARK: - Initializer

    init(model: MissionCardModel, isExpanded: Bool, onToggle: @escaping () -> Void) {
        self.model = model
        self.isExpanded = isExpanded
        self.onToggle = onToggle
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model.id == rhs.model.id
        && lhs.isExpanded == rhs.isExpanded
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing8) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
                HStack(spacing: DefaultSpacing.spacing4) {
                    ChipButton("Week \(model.week)", isSelected: false)
                        .buttonSize(.small)

                    ChipButton(model.platform, isSelected: false)
                        .buttonSize(.small)
                }

                Text(model.title)
                    .appFont(
                        .calloutEmphasis,
                        color: model.status == .inProgress
                        ? Color.indigo500 : .grey900)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            statusSection
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    private var statusSection: some View {
        HStack {
            StatusBadgePresenter(status: model.status)
                .equatable()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14))
                .foregroundStyle(Color.grey600)
        }
    }
}

// MARK: - Constants

private enum StatusBadgeConstants {
    static let badgePadding: CGFloat = 8
    static let borderWidth: CGFloat = 1
}

// MARK: - StatusBadgePresenter

/// 상태 뱃지 표시
private struct StatusBadgePresenter: View, Equatable {

    // MARK: - Property

    let status: MissionStatus

    // MARK: - Body

    var body: some View {
        Text(status.displayText)
            .appFont(.caption1, weight: .bold, color: status.foregroundColor)
            .padding(DefaultConstant.badgePadding)
            .background(status.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            .overlay {
                if status.hasBorder {
                    RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                        .stroke(Color.indigo500, lineWidth: StatusBadgeConstants.borderWidth)
                }
            }
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("MissionCardHeader - All Status") {
    VStack(spacing: 16) {
        ForEach(Array(MissionPreviewData.allStatusMissions.enumerated()), id: \.element.id) { index, mission in
            MissionCardHeader(
                model: mission,
                isExpanded: index == 1
            ) { }
        }
    }
    .padding()
}

#Preview("MissionCardHeader - iOS Missions") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(MissionPreviewData.iosMissions) { mission in
                MissionCardHeader(
                    model: mission,
                    isExpanded: false
                ) { }
            }
        }
        .padding()
    }
}
#endif
