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
    
    private let onTap: () -> Void

    init(
        session: Session,
        isExpanded: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    static func == (lsh: Self, rhs: Self) -> Bool {
        lsh.session.id == rhs.session.id
        && lsh.isExpanded == rhs.isExpanded
        && lsh.session.attendanceStatus == rhs.session.attendanceStatus
    }
    
    private enum Constants {
        static let containerPadding: CGFloat = 16
        static let containerHeight: CGFloat = 90
        static let iconSize: CGFloat = 64
        static let statusBadgeHeight: CGFloat = 36
        static let statusBadgeMinCornerRadius: Edge.Corner.Style = 12
    }
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            icon
            contentSection
            Spacer()
            statusSession
        }
        .padding(Constants.containerPadding)
        .frame(height: Constants.containerHeight)
        .containerShape(.rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .background(.white, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var icon: some View {
        Image(info.icon)
            .resizable()
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .scaledToFit()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text(info.title)
                .appFont(.bodyEmphasis, weight: .bold, color: .black)
                .lineLimit(1)

            Text(info.startTime.timeRange(to: info.endTime))
                .appFont(.callout, color: .gray)
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
            session: AttendancePreviewData.sessions[1]
        )
    }
}
