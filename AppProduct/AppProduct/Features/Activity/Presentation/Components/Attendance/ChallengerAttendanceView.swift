//
//  ChallengerAttendanceView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import SwiftUI

/// 챌린저(일반 참여자)의 출석 체크 화면
///
/// 지도와 출석 버튼을 표시하며, 지오펜싱 상태에 따라 버튼 활성화를 제어합니다.
struct ChallengerAttendanceView: View, Equatable {
    @State private var mapViewModel: BaseMapViewModel
    @Bindable private var attendanceViewModel: ChallengerAttendanceViewModel
    @Namespace private var attendanceNamespace
    @State private var showReasonSheet: Bool = false

    private let userId: UserID
    private let container: DIContainer
    private let errorHandler: ErrorHandler
    private let session: Session

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        mapViewModel: BaseMapViewModel,
        attendanceViewModel: ChallengerAttendanceViewModel,
        userId: UserID,
        session: Session
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.session = session
        self._mapViewModel = .init(
            wrappedValue: .init(
                container: container,
                info: session.info,
                errorHandler: errorHandler))
        self.attendanceViewModel = attendanceViewModel
        self.userId = userId
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.userId == rhs.userId
    }

    private enum Constants {
        static let bottomPadding: CGFloat = 16
        static let attendanceActionId = "attendance-action"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ActivityCompactMapView(
                container: container,
                errorHandler: errorHandler,
                info: session.info
            )
            attendanceActionView
            lateReasonButton
        }
        .animation(.smooth, value: session.attendanceStatus)
    }

    // MARK: - View Component

    /// 출석 상태에 따른 액션 뷰 (버튼 또는 승인 대기 카드)
    @ViewBuilder
    private var attendanceActionView: some View {
        GlassEffectContainer {
            switch session.attendanceStatus {
            case .pendingApproval:
                // 승인 대기 카드 (버튼에서 모핑 전환)
                PendingApprovalView()
                    .glassEffect(
                        .regular,
                        in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
                    .glassEffectID(
                        Constants.attendanceActionId, in: attendanceNamespace)

            case .beforeAttendance:
                // 출석 버튼
                attendanceButton
                    .glassEffectID(
                        Constants.attendanceActionId, in: attendanceNamespace)

            case .present, .late, .absent:
                // 확정 상태 - 버튼 비활성화
                attendanceButton
            }
        }
    }

    private var attendanceButton: some View {
        MainButton(attendanceViewModel.buttonStyle(for: session)) {
            triggerHaptic()
            Task {
                await attendanceViewModel.attendanceBtnTapped(
                    userId: userId, session: session)
                triggerSuccessHaptic()
            }
        }
        .buttonStyle(.glassProminent)
        .disabled(!attendanceViewModel.isAttendanceAvailable(for: session))
    }

    private var lateReasonButton: some View {
        Button {
            showReasonSheet = true
        } label: {
            Text("위치 인증이 안 되나요? 사유 제출하기")
                .appFont(.caption1, color: .gray)
                .underline()
        }
        .buttonStyle(.plain)
        .disabled(!attendanceViewModel.isAttendanceAvailable(for: session))
        .sheet(isPresented: $showReasonSheet) {
            AttendanceReasonSheet { reason in
                await attendanceViewModel.submitAttendanceReason(
                    userId: userId,
                    session: session,
                    reason: reason
                )
            }
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Previews

#Preview("출석 전 상태") {
    ChallengerAttendanceView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler,
        mapViewModel: AttendancePreviewData.mapViewModel,
        attendanceViewModel: AttendancePreviewData.attendanceViewModel,
        userId: AttendancePreviewData.userId,
        session: AttendancePreviewData.beforeAttendanceSession
    )
}

#Preview("승인 대기 상태") {
    ChallengerAttendanceView(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler,
        mapViewModel: AttendancePreviewData.mapViewModel,
        attendanceViewModel: AttendancePreviewData.attendanceViewModel,
        userId: AttendancePreviewData.userId,
        session: AttendancePreviewData.pendingApprovalSession
    )
}
