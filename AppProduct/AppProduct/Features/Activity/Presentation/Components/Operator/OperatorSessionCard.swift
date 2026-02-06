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

            if sessionAttendance.pendingCount > 0 {
                pendingSection
            } else {
                completionSection
            }
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

    /// 헤더 섹션 (아이콘, 제목, 상태, 위치 버튼)
    private var headerSection: some View {
        HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
            SessionStatusIcon(status: currentSessionStatus)
                .equatable()

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

    /// 승인 대기 섹션 (탭 가능, 펼침/접힘)
    private var pendingSection: some View {
        Button {
            onPendingListTap()
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                    .renderingMode(.template)
                    .foregroundStyle(.orange)
                    .padding(DefaultConstant.iconPadding)

                Text("승인 대기 명단 확인하기")
                    .appFont(.calloutEmphasis, color: .orange)

                Spacer()

                Image(systemName: DefaultConstant.chevronForwardImage)
                    .renderingMode(.template)
                    .foregroundStyle(.orange)
                    .padding(DefaultConstant.iconPadding)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.glassProminent)
        .tint(.orange.opacity(Constants.backgroundOpacity))
    }

    /// 승인 완료 섹션
    private var completionSection: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .renderingMode(.template)
                .foregroundStyle(.green)
                .padding(DefaultConstant.iconPadding)

            Text("모든 출석 승인이 완료되었습니다.")
                .appFont(.calloutEmphasis, color: .green)
        }
        .padding(ActivityConstants.statusCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .green.opacity(Constants.backgroundOpacity),
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius)))
    }

    /// 상태 칩 (진행 중, 출결일, 예정)
    @ViewBuilder
    private var status: some View {
        Text(currentSessionStatus.displayText)
            .appFont(.footnote, color: currentSessionStatus.textColor)
    }

    /// 세션 상태 계산
    private var currentSessionStatus: SessionStatus {
        SessionStatus.from(startTime: info.startTime, endTime: info.endTime)
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
    
    /// 시간 포맷팅 (예: 14:00 - 18:00)
    private var formattedTime: String {
        info.startTime.timeRange(to: info.endTime)
    }

}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // 진행 중 - 승인 대기 있음
            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_1",
                    session: AttendancePreviewData.sessions[1],
                    attendanceRate: 0.85,
                    attendedCount: 34,
                    totalCount: 40,
                    pendingMembers: mockPendingMembers
                )
            )

            // 출결일 - 모두 승인 완료
            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_2",
                    session: AttendancePreviewData.sessions[0],
                    attendanceRate: 1.0,
                    attendedCount: 40,
                    totalCount: 40,
                    pendingMembers: []
                )
            )

            OperatorSessionCard(
                sessionAttendance: OperatorSessionAttendance(
                    serverID: "session_3",
                    session: AttendancePreviewData.sessions[3],
                    attendanceRate: 0.85,
                    attendedCount: 34,
                    totalCount: 40,
                    pendingMembers: mockPendingMembers
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
