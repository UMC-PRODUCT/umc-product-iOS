//
//  ChallengerAttendanceViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation

@Observable
final class ChallengerAttendanceViewModel {
    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol
    
    private(set) var currentSession: Session
    private(set) var attendance: Attendance
    
    var attendanceStatus: AttendenceStatus {
        attendance.status
    }
    
    var attendanceType: AttendenceType {
        attendance.type
    }
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        challengeAttendanceUseCase: ChallengerAttendanceUseCaseProtocol,
        session: Session,
        attendance: Attendance
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.challengeAttendanceUseCase = challengeAttendanceUseCase
        self.currentSession = session
        self.attendance = attendance
    }
    
    func attendanceBtnTapped(session: Session, userId: UserID) async {
        let attendanceStatus = challengeAttendanceUseCase.isWithinAttendanceTime(session: session)
        do {
            guard attendanceStatus == .pending else { return }
            attendance = try await challengeAttendanceUseCase.requestGPSAttendance(
                sessionId: session.sessionId, userId: userId)
        } catch {
            errorHandler.handle(
                error, context: .init(feature: "Activity", action: "attendanceBtnTapped"))
        }
    }
    
    func attendanceReaonBtnTapped(session: Session, userId: UserID, reason: String) async {
        let attendanceStatus = challengeAttendanceUseCase.isWithinAttendanceTime(session: session)
        do {
            guard attendanceStatus == .late, attendanceStatus == .absent else { return }
            attendance = try await challengeAttendanceUseCase.submitLateReason(
                sessionId: session.sessionId, userId: userId, reason: reason)
        } catch {
            errorHandler.handle(
                error, context: .init(feature: "Activity", action: "attendanceReaonBtnTapped"))
        }
    }
}
