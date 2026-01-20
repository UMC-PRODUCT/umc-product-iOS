//
//  OperatorAttendanceUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Protocol

protocol OperatorAttendanceUseCaseProtocol {
    func fetchPendingAttendances(sessionId: SessionID) async throws -> [Attendance]
    func approveAttendance(attendanceId: AttendanceID) async throws -> Attendance
    func approveAllAttendances(sessionId: SessionID) async throws -> [Attendance]
    func rejectAttendance(attendanceId: AttendanceID, reason: String) async throws -> Attendance
    func fetchSessionAttendances(sessionId: SessionID) async throws -> [Attendance]
}
