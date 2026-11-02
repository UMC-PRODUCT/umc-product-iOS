//
//  ChallengerSessionCard.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 출석 가능한 세션 한 건을 표시하는 카드
///
/// 작은 아이콘 옆에 제목과 시간·상태를 두 줄로 모아 표시합니다.
/// 상위 리스트에서 탭하면 지도·출석 버튼이 있는 상세가 펼쳐집니다.
struct ChallengerSessionCard: View, Equatable {

    // MARK: - Property

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let session: Session
    private let isExpanded: Bool
    private let onTap: () -> Void

    private var info: SessionInfo {
        session.info
    }

    // MARK: - Init

    init(
        session: Session,
        isExpanded: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.session.id == rhs.session.id
            && lhs.isExpanded == rhs.isExpanded
            && lhs.session.attendanceStatus == rhs.session.attendanceStatus
    }

    // MARK: - Constants

    fileprivate enum Constants {
        static let titleLineLimit: Int = 2
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
                Image(systemName: info.category.symbol)
                    .font(.app(.body))
                    .foregroundStyle(info.category.color)
                    .frame(width: DefaultSpacing.spacing32, height: DefaultSpacing.spacing32)
                    .background(info.category.color.opacity(0.12), in: .rect(cornerRadius: DefaultSpacing.spacing8))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(info.title)
                        .appFont(.callout, weight: .semibold, color: .grey900)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : Constants.titleLineLimit)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    metadataLayout {
                        Text(info.startTime.timeRange(to: info.endTime))
                            .appFont(.subheadline, color: .grey600)

                        if !(isExpanded && session.attendanceStatus == .pendingApproval) {
                            statusBadge
                        }
                    }
                }

                Image(
                    systemName: isExpanded
                        ? DefaultConstant.chevronUpImage
                        : DefaultConstant.chevronDownImage
                )
                .font(.app(.caption1))
                .foregroundStyle(Color.grey400)
            }
            .padding(.horizontal, DefaultSpacing.spacing12)
            .padding(.vertical, DefaultSpacing.spacing8)
            .frame(minHeight: DefaultConstant.minimumTouchTarget)
            .background(Color.Surface.content, in: .rect(cornerRadius: DefaultSpacing.spacing16))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? "펼침" : "접힘")
        .accessibilityHint(isExpanded ? "탭하면 접습니다" : "탭하면 출석 정보를 펼칩니다")
    }

    // MARK: - View Components

    private var metadataLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DefaultSpacing.spacing4))
            : AnyLayout(FlowLayout(spacing: DefaultSpacing.spacing8))
    }

    /// 출석 상태 배지
    private var statusBadge: some View {
        Text(session.attendanceStatus.displayText)
            .appFont(
                .caption1,
                weight: .semibold,
                color: session.attendanceStatus.fontColor
            )
            .padding(.horizontal, DefaultSpacing.spacing8)
            .padding(.vertical, DefaultSpacing.spacing4)
            .background(session.attendanceStatus.backgroundColor, in: Capsule())
    }
}

#if DEBUG
// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    let info = SessionInfo(
        sessionId: SessionID(value: "preview"),
        iconName: "calendar.badge",
        title: "3주차 정기 세션",
        week: 3,
        startTime: .now,
        endTime: .now.addingTimeInterval(7_200),
        location: Coordinate(latitude: 37.5, longitude: 127.0)
    )
    let presentAttendance = Attendance(
        sessionId: info.sessionId,
        userId: UserID(value: "U-1"),
        type: .gps,
        status: .present,
        reason: nil
    )

    ZStack {
        Color.grey100.frame(height: 300)

        VStack(spacing: DefaultSpacing.spacing12) {
            ChallengerSessionCard(
                session: Session(info: info, initialAttendance: nil)
            )
            ChallengerSessionCard(
                session: Session(info: info, initialAttendance: presentAttendance)
            )
        }
        .padding()
    }
}
#endif
