//
//  MyAttendanceCard.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - MyAttendanceCard

/// 나의 출석 현황 카드
struct MyAttendanceCard: View {
    // MARK: - Property

    private let model: MyAttendanceItemModel

    // MARK: - Init

    init(model: MyAttendanceItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        MyAttendanceItemPresenter(model: model)
            .equatable()
            .glass()
    }
}

// MARK: - Presenter

private struct MyAttendanceItemPresenter: View, Equatable {
    let model: MyAttendanceItemModel

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model
    }
    
    private enum Constants {
        // Layout
        static let cardSpacing: CGFloat = 12
        static let cardPadding: EdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        static let cardRadius: CGFloat = 12

        // Week Tag
        static let weekTagPadding: EdgeInsets = .init(top: 2, leading: 8, bottom: 2, trailing: 8)
        static let weekTagRadius: CGFloat = 4

        // Status Badge
        static let statusPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let statusRadius: Edge.Corner.Style = 8

        // Time Icon
        static let timeIconSpacing: CGFloat = 4
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            weekTag
            contentSection
            Spacer()
            statusBadge
        }
        .padding(Constants.cardPadding)
        .containerShape(.rect(cornerRadius: Constants.cardRadius))
        .background(
            .white, in: RoundedRectangle(cornerRadius: Constants.cardRadius))
    }

    // MARK: - Subviews

    private var weekTag: some View {
        Text(model.weekText)
            .appFont(.caption1, color: .grey600)
            .padding(Constants.weekTagPadding)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.weekTagRadius)
                    .strokeBorder(.grey200)
            )
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.title)
                .appFont(.bodyEmphasis, color: .grey900)

            // 시간 범위
            timeRangeView
        }
    }

    private var timeRangeView: some View {
        HStack(spacing: Constants.timeIconSpacing) {
            Image(systemName: "clock")
                .font(.caption)
            Text(model.timeRange)
        }
        .appFont(.footnote, color: .grey500)
    }

    private var statusBadge: some View {
        Text(model.status.text)
            .appFont(.caption1Emphasis, color: model.status.fontColor)
            .padding(Constants.statusPadding)
            .background(
                model.status.backgroundColor,
                in: ConcentricRectangle(
                    corners: .concentric(minimum: Constants.statusRadius),
                    isUniform: true)
            )
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    let now = Date()

    VStack(spacing: 8) {
        MyAttendanceCard(
            model: .init(
                week: 1,
                title: "정기 세션",
                startTime: now,
                endTime: now.addingTimeInterval(4 * 3600),
                status: .present
            )
        )

        MyAttendanceCard(
            model: .init(
                week: 2,
                title: "정기 세션",
                startTime: now,
                endTime: now.addingTimeInterval(4 * 3600),
                status: .late
            )
        )

        MyAttendanceCard(
            model: .init(
                week: 3,
                title: "정기 세션",
                startTime: now,
                endTime: now.addingTimeInterval(4 * 3600),
                status: .absent
            )
        )
    }
    .padding()
    .background(Color.grey100)
}
