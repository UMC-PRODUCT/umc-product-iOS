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

    /// GPS 기반 출석 요청 (pending 상태로 서버 전송)
    /// - throws: LocationError.notAuthorized, LocationError.locationFailed, DomainError.attendanceOutOfRange
    func requestGPSAttendance(sessionId: SessionID, userId: UserID) async throws -> Attendance
    
    /// 지각 사유 제출
    /// - throws: DomainError.attendanceReasonRequired
    func submitLateReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance
    
    /// 불참 사유 제출
    /// - throws: DomainError.attendanceReasonRequired
    func submitAbsentReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance
    
    /// 출석 가능 시간 내인지 확인
    func isWithinAttendanceTime(session: Session) -> AttendenceStatus
    
    /// 현재 위치 좌표 통한 지오코딩
    /// - throws: LocationArror.locationFailed
    func getAddressToCurrentLocation() async throws -> String
}
