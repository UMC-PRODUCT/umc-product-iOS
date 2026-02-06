//
//  AttendanceStatsRow.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import SwiftUI

/// 운영진 세션 카드 출석 통계 행
///
/// 출석률 게이지바, 날짜/시간, 출석 인원을 표시합니다.
struct AttendanceStatsRow: View, Equatable {

    // MARK: - Property

    private let sessionAttendance: OperatorSessionAttendance

    private var session: Session {
        sessionAttendance.session
    }

    private var info: SessionInfo {
        session.info
    }

    // MARK: - Initializer

    init(sessionAttendance: OperatorSessionAttendance) {
        self.sessionAttendance = sessionAttendance
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sessionAttendance.attendanceRate == rhs.sessionAttendance.attendanceRate
            && lhs.sessionAttendance.attendedCount == rhs.sessionAttendance.attendedCount
            && lhs.sessionAttendance.totalCount == rhs.sessionAttendance.totalCount
            && lhs.sessionAttendance.pendingCount == rhs.sessionAttendance.pendingCount
            && lhs.sessionAttendance.session.info.startTime == rhs.sessionAttendance.session.info.startTime
            && lhs.sessionAttendance.session.info.endTime == rhs.sessionAttendance.session.info.endTime
    }

    // MARK: - Constant

    private enum Constants {
        static let progressBarHeight: CGFloat = 8
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            percentageHeader
            progressGauge
        }
    }

    // MARK: - Function

    /// 퍼센트 헤더 (우측 정렬)
    private var percentageHeader: some View {
        HStack {
            Text("\(progressPercentage)%")
                .appFont(.bodyEmphasis, color: .indigo500)
            
            Spacer()
            
            Text("\(sessionAttendance.attendedCount)/\(sessionAttendance.totalCount)")
                .appFont(.calloutEmphasis, color: .indigo500)
        }
    }

    /// 게이지바 (CurriculumProgressCard 패턴)
    private var progressGauge: some View {
        Gauge(value: sessionAttendance.attendanceRate) {
            EmptyView()
        }
        .gaugeStyle(.linearCapacity)
        .tint(
            LinearGradient(
                colors: [.indigo300, .indigo600],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(height: Constants.progressBarHeight)
    }
    
    /// 퍼센트 계산
    private var progressPercentage: Int {
        Int(sessionAttendance.attendanceRate * 100)
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        Color.grey100.frame(height: 300)

        AttendanceStatsRow(
            sessionAttendance: OperatorSessionAttendance(
                serverID: "preview",
                session: AttendancePreviewData.sessions[0],
                attendanceRate: 0.85,
                attendedCount: 34,
                totalCount: 40,
                pendingMembers: []
            )
        )
        .padding()
    }
}
