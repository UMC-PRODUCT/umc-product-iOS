//
//  AttendanceSessionView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/22/26.
//

import SwiftUI

struct AttendanceSessionView: View {
    @State private var expandedSessionId: Session.ID?
    @State private var attendanceViewModel: ChallengerAttendanceViewModel
    @State private var sessionViewModel: ChallengerSessionViewModel
    
    private let container: DIContainer
    private let errorHandler: ErrorHandler
    private let sessions: [Session]
    private let userId: UserID
    private let categoryFor: (String) -> ScheduleIconCategory

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessions: [Session],
        userId: UserID,
        categoryFor: @escaping (String) -> ScheduleIconCategory
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.sessions = sessions
        self.userId = userId
        self.categoryFor = categoryFor
        
        let useCaseProvider = container.resolve(UsecaseProviding.self)
        let repositoryProvider = container.resolve(ActivityRepositoryProviding.self)

        self._attendanceViewModel = .init(wrappedValue: .init(
            container: container,
            errorHandler: errorHandler,
            challengeAttendanceUseCase: useCaseProvider.activity.challengerAttendanceUseCase
        ))
        self._sessionViewModel = .init(wrappedValue: .init(
            container: container,
            errorHandler: errorHandler,
            sessionRepository: repositoryProvider.sessionRepository
        ))
    }
    
    private enum Constants {
        static let animationResponse: Double = 0.35
        static let animationDamping: Double = 0.8
    }

    // MARK: - Computed Properties

    /// 출석 가능한 세션만 필터링 (beforeAttendance, pendingApproval)
    private var availableSessions: [Session] {
        sessions.filter(\.isAttendanceAvailable)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing48) {
                attendanceSessionSection
                
                myAttendanceStatusView
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .safeAreaPadding(.bottom, DefaultConstant.defaultSafeBottom)
        }
        .contentMargins(
            .trailing,
            DefaultConstant.defaultContentTrailingMargins,
            for: .scrollContent)
        .contentMargins(
            .bottom,
            DefaultConstant.defaultContentBottomMargins,
            for: .scrollContent)
        .onDisappear {
            Task {
                await attendanceViewModel.geofenceCleanup()
            }
        }
    }
    
    @ViewBuilder
    private var attendanceSessionSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            attendanceSectionHeader

            if availableSessions.isEmpty {
                emptySessionView
            } else {
                AttendanceSessionList(
                    container: container,
                    errorHandler: errorHandler,
                    sessions: availableSessions,
                    expandedSessionId: expandedSessionId,
                    attendanceViewModel: attendanceViewModel,
                    userId: userId
                ) { sessionId in
                    withAnimation(.spring(Spring(
                        response: Constants.animationResponse,
                        dampingRatio: Constants.animationDamping
                    ))) {
                        expandedSessionId = expandedSessionId == sessionId ? nil : sessionId
                    }
                }
                .equatable()
            }
        }
    }

    private var emptySessionView: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green.opacity(0.7))

            Text("모든 세션 출석을 완료했습니다")
                .appFont(.body, color: .grey600)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DefaultSpacing.spacing32)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
        .glass()
    }
    
    private var attendanceSectionHeader: some View {
        Text("출석 가능한 세션")
            .appFont(.bodyEmphasis, color: .black)
    }
    
    private var myAttendanceStatusView: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            sectionHeader

            MyAttendanceStatusView(
                sessions: sessions,
                categoryFor: categoryFor
            )
        }
    }
    
    private var sectionHeader: some View {
        Text("나의 출석 현황")
            .appFont(.bodyEmphasis, color: .black)
    }
}

#Preview("기본 (필터링 적용)") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        AttendanceSessionView(
            container: AttendancePreviewData.container,
            errorHandler: AttendancePreviewData.errorHandler,
            sessions: AttendancePreviewData.sessions,
            userId: AttendancePreviewData.userId,
            categoryFor: { _ in .general }
        )
    }
}

#Preview("출석 가능 세션 여러 개") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        AttendanceSessionView(
            container: AttendancePreviewData.container,
            errorHandler: AttendancePreviewData.errorHandler,
            sessions: AttendancePreviewData.multipleAvailableSessions,
            userId: AttendancePreviewData.userId,
            categoryFor: { _ in .general }
        )
    }
}

#Preview("모든 세션 완료 (Empty State)") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        // 모든 세션이 완료된 상태
        AttendanceSessionView(
            container: AttendancePreviewData.container,
            errorHandler: AttendancePreviewData.errorHandler,
            sessions: Array(AttendancePreviewData.sessions.prefix(5)), // beforeAttendance 제외
            userId: AttendancePreviewData.userId,
            categoryFor: { _ in .general }
        )
    }
}
