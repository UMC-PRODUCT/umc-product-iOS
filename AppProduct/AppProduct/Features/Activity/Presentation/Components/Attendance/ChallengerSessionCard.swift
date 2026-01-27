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
        static let iconSize: CGFloat = 64
        static let statusBadgeHeight: CGFloat = 36
        static let statusBadgeMinCornerRadius: Edge.Corner.Style = 12
        static let statusBadgeCornerRadius: CGFloat = 12
    }
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            CardIconImage(
                image: info.category.symbol,
                color: info.category.color,
                isLoading: .constant(false))
            contentSection
                .frame(maxWidth: .infinity, alignment: .leading)
            statusSession
        }
        .padding(DefaultConstant.defaultListPadding)
        .containerShape(
            .rect(cornerRadius: DefaultConstant.defaultListCornerRadius))
        .background(.white, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .glass()
    }
    
    private var icon: some View {
        Image(systemName: info.category.symbol)
        // TODO: Icon 관련 Modifier는 Custom Modifier로 추후 합치는게 좋을듯 - [25.01.27] 이재원
            .foregroundStyle(info.category.color)
            .frame(width: DefaultConstant.iconSize, height: DefaultConstant.iconSize)
            .padding(DefaultConstant.iconPadding)
            .background(info.category.color.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text(info.title)
                .appFont(.bodyEmphasis, weight: .bold, color: .black)
                .lineLimit(2)

            Text(info.startTime.timeRange(to: info.endTime))
                .appFont(.callout, color: .gray)
        }
    }

    private var statusSession: some View {
        HStack {
            // 펼침 상태 + 승인 대기일 때 배지 숨김
            if !(isExpanded && session.attendanceStatus == .pendingApproval) {
                statusBadge
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .foregroundStyle(.gray)
        }
    }

    /// 출석 상태 배지
    private var statusBadge: some View {
        Text(session.attendanceStatus.displayText)
            .appFont(.caption1Emphasis, color: session.attendanceStatus.fontColor)
            .padding(DefaultConstant.badgePadding)
            .background(
                session.attendanceStatus.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.grey100.frame(height: 300)
        
        ChallengerSessionCard(
            session: AttendancePreviewData.sessions[1]
        )
    }
}
