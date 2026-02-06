//
//  OperatorSessionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import SwiftUI

/// 운영진 출석 관리 화면 세션 카드
///
/// 세션 정보와 출석 통계를 표시하며, 펼침 상태에서 승인 대기 명단을 보여줍니다.
struct OperatorSessionCard: View, Equatable {

    // MARK: - Property

    private let sessionAttendance: OperatorSessionAttendance
    private let onTap: () -> Void
    private let onLocationTap: () -> Void
    private let onPendingListTap: () -> Void
    private let onReasonTap: ((PendingMember) -> Void)?
    private let onRejectTap: ((PendingMember) -> Void)?
    private let onApproveTap: ((PendingMember) -> Void)?

    private var session: Session {
        sessionAttendance.session
    }

    private var info: SessionInfo {
        session.info
    }

    // MARK: - Initializer

    init(
        sessionAttendance: OperatorSessionAttendance,
        onTap: @escaping () -> Void = {},
        onLocationTap: @escaping () -> Void = {},
        onPendingListTap: @escaping () -> Void = {},
        onReasonTap: ((PendingMember) -> Void)? = nil,
        onRejectTap: ((PendingMember) -> Void)? = nil,
        onApproveTap: ((PendingMember) -> Void)? = nil
    ) {
        self.sessionAttendance = sessionAttendance
        self.onTap = onTap
        self.onLocationTap = onLocationTap
        self.onPendingListTap = onPendingListTap
        self.onReasonTap = onReasonTap
        self.onRejectTap = onRejectTap
        self.onApproveTap = onApproveTap
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sessionAttendance == rhs.sessionAttendance
    }

    // MARK: - Constant

    fileprivate enum Constants {
        static let mapPinIconSize: CGSize = .init(width: 24, height: 24)
        static let titleLineLimit: Int = 2
        static let statusRadius: CGFloat = 8
        static let clockIconSize: CGSize = .init(width: 14, height: 14)
        static let backgroundOpacity: CGFloat = 0.15
    }


    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            headerSection

            AttendanceStatsRow(sessionAttendance: sessionAttendance)
                .equatable()

            statusSection
        }
        .padding(DefaultConstant.defaultCardPadding)
        .background {
            ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius),
                isUniform: true
            )
            .fill(.white)
            .glass()
        }
    }

    // MARK: - Function

    /// 상태별 섹션 전환
    @ViewBuilder
    private var statusSection: some View {
        let style: StatusSectionStyle = {
            switch currentSessionStatus {
            case .beforeStart:
                return .beforeStart
            case .inProgress, .ended:
                return sessionAttendance.pendingCount > 0 ? .pending : .complete
            }
        }()

        statusSectionView(style: style)
    }

    /// 통합 상태 섹션 뷰
    private func statusSectionView(style: StatusSectionStyle) -> some View {
        Button {
            if style.isEnabled {
                onPendingListTap()
            }
        } label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Image(systemName: style.icon)
                    .renderingMode(.template)
                    .foregroundStyle(style.color)

                Text(style.text)
                    .appFont(.calloutEmphasis, color: style.color)

                if style.showChevron {
                    Spacer()

                    Image(systemName: DefaultConstant.chevronForwardImage)
                        .renderingMode(.template)
                        .foregroundStyle(style.color)
                }
            }
            .padding(ActivityConstants.statusCardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .glassEffect(
            style.isEnabled
            ? .regular.tint(style.backgroundColor).interactive()
            : .regular.tint(style.backgroundColor),
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
        .disabled(!style.isEnabled)
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
//            SessionStatusIcon(status: currentSessionStatus)
//                .equatable()

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(info.title)
                    .appFont(.calloutEmphasis, color: .black)
                    .lineLimit(Constants.titleLineLimit)

                HStack(spacing: DefaultSpacing.spacing8) {
                    sessionTime
                    status
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onLocationTap) {
                Image(.Map.mapPinGrey)
                    .resizable()
                    .font(.system(size: 12))
                    .foregroundStyle(.grey600)
                    .frame(
                        width: Constants.mapPinIconSize.width,
                        height: Constants.mapPinIconSize.height)
            }
            .buttonStyle(.glass)
        }
    }

    /// 상태 칩 (진행 중, 출결일, 예정)
    @ViewBuilder
    private var status: some View {
        Text(currentSessionStatus.displayText)
            .appFont(.footnote, color: currentSessionStatus.textColor)
    }

    /// 세션 상태 계산
    private var currentSessionStatus: OperatorSessionStatus {
        OperatorSessionStatus.from(startTime: info.startTime, endTime: info.endTime)
    }

    private var sessionTime: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Image(systemName: "clock")
                .resizable()
                .foregroundStyle(.gray)
                .frame(
                    width: Constants.clockIconSize.width,
                    height: Constants.clockIconSize.height)
            
            Text(formattedTime)
                .appFont(.footnote, color: .gray)
        }
    }
    /// 날짜 포맷팅
    private var formattedDate: String {
        info.startTime.toYearMonthDayWithWeekday()
    }
    
    /// 시간 포맷팅
    private var formattedTime: String {
        info.startTime.timeRange(to: info.endTime)
    }

}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 진행전 (beforeStart) - 미래 세션
            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_beforeStart",
                    session: AttendancePreviewData.sessions[10],
                    attendanceRate: 0.0,
                    attendedCount: 0,
                    totalCount: 40,
                    pendingMembers: []
                )
            )

            // 진행 중 (inProgress) - 승인 대기 있음
            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_inProgress",
                    session: AttendancePreviewData.sessions[9],
                    attendanceRate: 0.85,
                    attendedCount: 34,
                    totalCount: 40,
                    pendingMembers: mockPendingMembers
                )
            )

            // 종료됨 (ended) - 모두 승인 완료
            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_completed",
                    session: AttendancePreviewData.sessions[0],
                    attendanceRate: 1.0,
                    attendedCount: 40,
                    totalCount: 40,
                    pendingMembers: []
                )
            )
        }
        .padding()
    }
    .background(Color.grey100)
}

private let mockPendingMembers: [PendingMember] = [
    PendingMember(
        serverID: "1",
        name: "홍길동",
        nickname: "닉네임",
        university: "중앙대학교",
        requestTime: Date.now.addingTimeInterval(-300),
        reason: "지각 사유입니다"
    ),
    PendingMember(
        serverID: "2",
        name: "김철수",
        nickname: nil,
        university: "서울대학교",
        requestTime: Date.now.addingTimeInterval(-600),
        reason: nil
    ),
    PendingMember(
        serverID: "3",
        name: "이영희",
        nickname: "영희",
        university: "연세대학교",
        requestTime: Date.now.addingTimeInterval(-900),
        reason: "교통 지연으로 인한 지각"
    )
]
