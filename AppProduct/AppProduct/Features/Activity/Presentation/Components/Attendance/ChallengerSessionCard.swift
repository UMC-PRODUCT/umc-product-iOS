//
//  ChallengerSessionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import SwiftUI

struct ChallengerSessionCard: View, Equatable {
    private let isDarkMode: Bool
    private let sessionItem: SessionItem
    
    private var session: Session {
        sessionItem.session
    }
    
    init(sessionItem: SessionItem, isDarkMode: Bool = false) {
        self.sessionItem = sessionItem
        self.isDarkMode = isDarkMode
    }
    
    static func == (lsh: Self, rhs: Self) -> Bool {
        lsh.sessionItem.id == rhs.sessionItem.id
        && lsh.sessionItem.attendanceStatus == rhs.sessionItem.attendanceStatus
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
        Image(session.icon)
            .resizable()
            .frame(width: 64, height: 64)
            .scaledToFit()
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .appFont(.title3, weight: .bold, color: isDarkMode ? .white : .black)
                .lineLimit(1)
            
            Text(session.startTime.timeRange(to: session.endTime))
                .appFont(
                    .callout, color: .grey800)
        }
    }
    
    private var statusSession: some View {
        HStack {
            Text(sessionItem.attendanceStatus.displayText)
                .appFont(.caption1Emphasis, color: sessionItem.attendanceStatus.fontColor)
                .frame(height: 36)
                .padding(.horizontal)
                .background(
                    sessionItem.attendanceStatus.backgroundColor,
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
            sessionItem: AttendancePreviewData.sessionItem,
            isDarkMode: true
        )
    }
}
