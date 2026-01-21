//
//  AttendanceSessionList.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/21/26.
//

import SwiftUI

struct AttendanceSessionList: View, Equatable {
    @State private var expandedSessionId: Session.ID?
    @Bindable private var attendanceViewModel: ChallengerAttendanceViewModel
    
    private let container: DIContainer
    private let errorHandler: ErrorHandler
    private let sessions: [Session]
    private let userId: UserID
//    private let onSessionTap: (Session.ID) -> Void
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessions: [Session],
        attendanceViewModel: ChallengerAttendanceViewModel,
        userId: UserID,
//        onSessionTap: @escaping (Session.ID) -> Void
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.sessions = sessions
        self.attendanceViewModel = attendanceViewModel
        self.userId = userId
//        self.onSessionTap = onSessionTap
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sessions.map(\.id) == rhs.sessions.map(\.id)
        && lhs.expandedSessionId == rhs.expandedSessionId
        && lhs.userId == rhs.userId
    }
    
    private enum Constants {
        static let listSpacing: CGFloat = 12
        static let transitionScale: CGFloat = 0.95
    }
    
    var body: some View {
        List {
            ForEach(sessions, id: \.id) { session in
                sessionItem(for: session)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func sessionItem(for session: Session) -> some View {
        let isExpanded = expandedSessionId == session.id
        
        VStack(spacing: 12) {
            ChallengerSessionCard(
                session: session,
                isExpanded: isExpanded
            ) {
//                onSessionTap(session.id)
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
                .transition(.asymmetric(
                    insertion: .scale(scale: Constants.transitionScale).combined(with: .opacity),
                    removal: .scale(scale: Constants.transitionScale).combined(with: .opacity)))
            }
        }
        
    }
}

#Preview {
    AttendanceSessionList(
        container: AttendancePreviewData.container,
        errorHandler: AttendancePreviewData.errorHandler,
        sessions: [AttendancePreviewData.session],
        attendanceViewModel: AttendancePreviewData.attendanceViewModel,
        userId: AttendancePreviewData.userId,
    )
}
