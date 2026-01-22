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
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessions: [Session],
        userId: UserID
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.sessions = sessions
        self.userId = userId
        
        let challengerAttendanceUseCase = container.resolve(ChallengerAttendanceUseCaseProtocol.self)
        let sessionRepository = container.resolve(SessionRepositoryProtocol.self)
        
        self._attendanceViewModel = .init(wrappedValue: .init(
            container: container,
            errorHandler: errorHandler,
            challengeAttendanceUseCase: challengerAttendanceUseCase
        ))
        self._sessionViewModel = .init(wrappedValue: .init(
            container: container,
            errorHandler: errorHandler,
            sessionRepository: sessionRepository
        ))
    }
    
    private enum Constants {
        static let animationResponse: Double = 0.35
        static let animationDamping: Double = 0.8
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing48) {
                attendanceSessionSection
                
                myAttendanceStatusView
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
        .contentMargins(.trailing, 4, for: .scrollContent)
    }
    
    private var attendanceSessionSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            attendanceSectionHeader
            
            AttendanceSessionList(
                container: container,
                errorHandler: errorHandler,
                sessions: sessions,
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
    
    private var attendanceSectionHeader: some View {
        Text("출석 가능한 세션")
            .appFont(.bodyEmphasis, color: .black)
    }
    
    private var myAttendanceStatusView: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            sectionHeader
            
            MyAttendanceStatusView(sessions: sessions)
        }
    }
    
    private var sectionHeader: some View {
        Text("나의 출석 현황")
            .appFont(.bodyEmphasis, color: .black)
    }
}

#Preview {
    ZStack {
        Color.grey100.ignoresSafeArea()
        
        AttendanceSessionView(
            container: AttendancePreviewData.container,
            errorHandler: AttendancePreviewData.errorHandler,
            sessions: AttendancePreviewData.sessions,
            userId: AttendancePreviewData.userId
        )
    }
}
