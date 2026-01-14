//
//  ChallengerAttendanceView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import SwiftUI

struct ChallengerAttendanceView: View, Equatable {
    @Environment(\.di) private var container
    @Environment(ErrorHandler.self) private var errorHandler
    
    @Bindable private var mapViewModel: BaseMapViewModel
    @Bindable private var attendanceViewModel: ChallengerAttendanceViewModel
    private var session: Session
    private var attendance: Attendance
    private var userId: UserID
    
    init(
        challengerAttendanceUseCase: ChallengerAttendanceUseCaseProtocol,
        mapViewModel: BaseMapViewModel,
        attendanceViewModel: ChallengerAttendanceViewModel,
        session: Session,
        attendance: Attendance,
        userId: UserID
    ) {
        self.mapViewModel = mapViewModel
        self.attendanceViewModel = attendanceViewModel
        self.session = session
        self.attendance = attendance
        self.userId = userId
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.attendance.id == rhs.attendance.id
        && lhs.session.id == rhs.session.id
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ActivityCompactMapView(
                container: container,
                errorHandler: errorHandler,
                session: session
            )
            
            attendanceButton
        }
    }
    
    private var attendanceButton: some View {
        MainButton("현 위치로 출석체크") {
            Task {
                await attendanceViewModel.attendanceBtnTapped(
                    session: session, userId: userId)
            }
            print(attendanceViewModel.attendance)
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    ChallengerAttendanceView(
        challengerAttendanceUseCase: AttendancePreviewData.challengerAttendanceUseCase,
        mapViewModel: AttendancePreviewData.mapViewModel,
        attendanceViewModel: AttendancePreviewData.attendanceViewModel,
        session: AttendancePreviewData.session,
        attendance: AttendancePreviewData.attendance,
        userId: AttendancePreviewData.userId
    )
    .environment(\.di, AttendancePreviewData.container)
    .environment(AttendancePreviewData.errorHandler)
}
