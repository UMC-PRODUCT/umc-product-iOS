//
//  ChallengerSessionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import SwiftUI

struct ChallengerSessionCard: View, Equatable {
    private let session: Session
    private let isExpanded: Bool

    private var info: SessionInfo {
        session.info
    }

    init(
        session: Session,
        isExpanded: Bool = false
    ) {
        self.session = session
        self.isExpanded = isExpanded
    }

    static func == (lsh: Self, rhs: Self) -> Bool {
        lsh.session.id == rhs.session.id
        && lsh.isExpanded == rhs.isExpanded
        && lsh.session.attendanceStatus == rhs.session.attendanceStatus
    }
    
    private enum Constants {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let containerPadding: CGFloat = 16
        static let containerHeight: CGFloat = 90
        static let containerCornerRadius: CGFloat = 24
        static let iconSize: CGFloat = 64
        static let statusBadgeHeight: CGFloat = 36
        static let statusBadgeMinCornerRadius: Edge.Corner.Style = 12
    }
    
    var body: some View {
        HStack(spacing: Constants.horizontalSpacing) {
            icon
            contentSection
            statusSession
        }
        .padding(Constants.containerPadding)
        .frame(height: Constants.containerHeight)
        .containerShape(.rect(cornerRadius: Constants.containerCornerRadius))
        .background(.grey000, in: .rect(cornerRadius: Constants.containerCornerRadius))
    }
    
    private var icon: some View {
        Image(info.icon)
            .resizable()
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .scaledToFit()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            Text(info.title)
                .appFont(.bodyEmphasis, weight: .bold, color: .grey900)
                .lineLimit(1)

            Text(info.startTime.timeRange(to: info.endTime))
                .appFont(
                    .callout, color: .grey800)
        }
    }

    private var statusSession: some View {
        HStack {
            Text(session.attendanceStatus.displayText)
                .appFont(.caption1Emphasis, color: session.attendanceStatus.fontColor)
                .frame(height: Constants.statusBadgeHeight)
                .padding(.horizontal)
                .background(
                    session.attendanceStatus.backgroundColor,
                    in: ConcentricRectangle(
                        corners: .concentric(minimum: Constants.statusBadgeMinCornerRadius),
                        isUniform: true
                    )
                )

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .foregroundStyle(.gray)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.gray.frame(height: 300)
        
        ChallengerSessionCard(
            session: AttendancePreviewData.session
        )
    }
}
