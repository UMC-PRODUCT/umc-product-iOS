//
//  ChallengerMyAttendanceCard.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - ChallengerMyAttendanceCard

/// 나의 출석 현황 카드
struct ChallengerMyAttendanceCard: View {
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
    }
}

// MARK: - Presenter

private struct MyAttendanceItemPresenter: View, Equatable {
    let model: MyAttendanceItemModel

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model
    }
    
    private enum Constants {
        static let cardSpacing: CGFloat = 12
        static let cardRadius: CGFloat = 12
        static let contentSectionSpacing: CGFloat = 4

        static let weekTagPadding: EdgeInsets = .init(top: 2, leading: 8, bottom: 2, trailing: 8)
        static let weekTagRadius: CGFloat = 4

        static let statusPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let statusRadius: CGFloat = 8

        static let timeIconSpacing: CGFloat = 4
    }

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            CardIconImage(
                image: model.category.symbol,
                color: model.category.color,
                isLoading: .constant(false))
            contentSection
            Spacer()
            statusBadge
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(.white)
    }

    // MARK: - Subviews
    
    private var contentSection: some View {
        VStack(
            alignment: .leading,
            spacing: Constants.contentSectionSpacing
        ) {
            Text(model.title)
                .appFont(.bodyEmphasis, color: .black)
                .lineLimit(3)

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
            .padding(DefaultConstant.badgePadding)
            .background(
                model.status.backgroundColor,
                in: RoundedRectangle(cornerRadius: Constants.statusRadius)
            )
            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }
}

#if DEBUG
// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    let now = Date()

    VStack(spacing: 8) {
        ChallengerMyAttendanceCard(
            model: .init(
                week: 1,
                title: "정기 세션",
                startTime: now,
                endTime: now.addingTimeInterval(4 * 3600),
                status: .present,
                category: .general
            )
        )
    }
    .frame(height: 200)
    .background(Color.grey100)
}
#endif
