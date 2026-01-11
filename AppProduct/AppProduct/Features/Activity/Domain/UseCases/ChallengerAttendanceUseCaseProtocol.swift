//
//  ChallengerAttendanceUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Protocol

protocol ChallengerAttendanceUseCaseProtocol {
    var isInsideGeofence: Bool { get }
    var isLocationAuthorized: Bool { get }

    func requestGPSAttendance(sessionId: SessionID, userId: UserID) async throws -> Attendance
    func submitLateReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance
    func submitAbsentReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance
    func isWithinAttendanceTime(session: Session) -> Bool
}
