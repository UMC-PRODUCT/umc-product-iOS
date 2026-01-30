//
//  MissionCardHeader.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - Constants

fileprivate enum Constants {
    static let chevronIconSize: CGFloat = 14
    static let borderWidth: CGFloat = 1
    static let tagBadgeCornerRadius: CGFloat = 12
}

// MARK: - MissionCardHeader

/// 미션 카드 헤더 뷰
///
/// 주차/플랫폼 태그, 제목, 상태 뱃지, 펼치기/접기 버튼을 표시합니다.
struct MissionCardHeader: View, Equatable {

    // MARK: - Property

    private let model: MissionCardModel
    private let isExpanded: Bool
    private let onToggle: () -> Void

    // MARK: - Initializer

    init(
        model: MissionCardModel,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) {
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
            contentSection
            Spacer()
            statusSection
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    // MARK: - View Components

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            tagSection
            titleText
        }
    }

    private var tagSection: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            InfoBadge(
                text: "Week \(model.week)",
                foregroundColor: .grey600,
                backgroundColor: .grey100
            )

            InfoBadge(
                text: model.platform,
                foregroundColor: .grey600,
                backgroundColor: .grey100
            )
        }
    }

    private var titleText: some View {
        Text(model.title)
            .appFont(
                .calloutEmphasis,
                color: model.status == .inProgress
                ? Color.indigo500 : .grey900)
            .multilineTextAlignment(.leading)
    }

    private var statusSection: some View {
        HStack {
            StatusBadgePresenter(status: model.status)
                .equatable()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: Constants.chevronIconSize))
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - InfoBadge

/// 정보 표시용 뱃지 (태그, 상태 등)
fileprivate struct InfoBadge: View, Equatable {

    // MARK: - Property

    let text: String
    let foregroundColor: Color
    let backgroundColor: Color
    var hasBorder: Bool = false
    var borderColor: Color = .indigo500
    var cornerRadius: CGFloat = Constants.tagBadgeCornerRadius

    // MARK: - Body

    var body: some View {
        Text(text)
            .appFont(.subheadline, weight: .bold, color: foregroundColor)
            .padding(DefaultConstant.badgePadding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if hasBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(borderColor, lineWidth: Constants.borderWidth)
                }
            }
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - StatusBadgePresenter

/// 상태 뱃지 표시 (InfoBadge 활용)
private struct StatusBadgePresenter: View, Equatable {

    // MARK: - Property

    let status: MissionStatus

    // MARK: - Body

    var body: some View {
        InfoBadge(
            text: status.displayText,
            foregroundColor: status.foregroundColor,
            backgroundColor: status.backgroundColor,
            hasBorder: status.hasBorder,
            borderColor: .indigo500,
            cornerRadius: DefaultConstant.cornerRadius
        )
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
