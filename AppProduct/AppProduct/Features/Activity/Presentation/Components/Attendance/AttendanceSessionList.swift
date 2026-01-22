//
//  AttendanceSessionList.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/21/26.
//

import SwiftUI

struct AttendanceSessionList: View, Equatable {
    private var expandedSessionId: Session.ID?
    private var attendanceViewModel: ChallengerAttendanceViewModel
    
    private let container: DIContainer
    private let errorHandler: ErrorHandler
    private let sessions: [Session]
    private let userId: UserID
    private let onSessionTap: (Session.ID) -> Void
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessions: [Session],
        expandedSessionId: Session.ID?,
        attendanceViewModel: ChallengerAttendanceViewModel,
        userId: UserID,
        onSessionTap: @escaping (Session.ID) -> Void
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.sessions = sessions
        self.expandedSessionId = expandedSessionId
        self.attendanceViewModel = attendanceViewModel
        self.userId = userId
        self.onSessionTap = onSessionTap
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sessions.map(\.id) == rhs.sessions.map(\.id)
        && lhs.expandedSessionId == rhs.expandedSessionId
        && lhs.userId == rhs.userId
    }
    
    private enum Constants {
        static let listSpacing: CGFloat = 12
        static let transitionScale: CGFloat = 0.95
        static let scrollDelay: Double = 0.1
        static let scrollAnimationResponse: Double = 0.35
        static let scrollAnimationDamping: Double = 0.75
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Constants.listSpacing) {
                ForEach(sessions, id: \.id) { session in
                    sessionItem(for: session)
                }
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func sessionItem(for session: Session) -> some View {
        let isExpanded = expandedSessionId == session.id
        
        VStack(spacing: 12) {
            ChallengerSessionCard(
                session: session,
                isExpanded: isExpanded
            ) {
                onSessionTap(session.id)
            }
            .equatable()

            if isExpanded {
                ChallengerAttendanceView(
                    container: container,
                    errorHandler: errorHandler,
                    mapViewModel: .init(
                        container: container,
                        info: session.info,
                        errorHandler: errorHandler
                    ),
                    attendanceViewModel: attendanceViewModel,
                    userId: userId,
                    session: session
                )
                .equatable()
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .transition(.asymmetric(
                    insertion: .scale(scale: Constants.transitionScale).combined(with: .opacity),
                    removal: .scale(scale: Constants.transitionScale).combined(with: .opacity)))
            }
        }
    }
}
