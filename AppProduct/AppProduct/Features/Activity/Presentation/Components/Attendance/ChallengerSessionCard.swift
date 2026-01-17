//
//  ChallengerSessionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import SwiftUI

struct ChallengerSessionCard: View, Equatable {
    private let isDarkMode: Bool
    private let session: Session

    private var info: SessionInfo {
        session.info
    }

    init(session: Session, isDarkMode: Bool = false) {
        self.session = session
        self.isDarkMode = isDarkMode
    }

    static func == (lsh: Self, rhs: Self) -> Bool {
        lsh.session.id == rhs.session.id
        && lsh.session.attendanceStatus == rhs.session.attendanceStatus
        && lsh.isDarkMode == rhs.isDarkMode
    }
    
    var body: some View {
        HStack(spacing: 16) {
            icon
            contentSection
            statusSession
        }
        .padding(16)
        .frame(height: 90)
        .background(.grey100, in: .rect(cornerRadius: 24))
        .containerShape(.rect(cornerRadius: 24))
    }
    
    private var icon: some View {
        Image(info.icon)
            .resizable()
            .frame(width: 64, height: 64)
            .scaledToFit()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(info.title)
                .appFont(.title3, weight: .bold, color: isDarkMode ? .white : .black)
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
                .frame(height: 36)
                .padding(.horizontal)
                .background(
                    session.attendanceStatus.backgroundColor,
                    in: ConcentricRectangle())

            Image(systemName: "chevron.down")
                .foregroundStyle(.gray)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.gray
        ChallengerSessionCard(
            session: AttendancePreviewData.session,
            isDarkMode: true
        )
    }
}
