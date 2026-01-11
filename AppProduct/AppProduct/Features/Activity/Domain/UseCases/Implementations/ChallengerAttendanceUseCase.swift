//
//  ChallengerAttendanceUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/9/26.
//

import Foundation

// MARK: - Implementation

final class ChallengerAttendanceUseCase: ChallengerAttendanceUseCaseProtocol {

    // MARK: - Property

    private let repository: AttendanceRepositoryProtocol
    private let locationManager: LocationManager

    // MARK: - Computed Property

    var isInsideGeofence: Bool {
        locationManager.isInsideGeofence
    }

    var isLocationAuthorized: Bool {
        locationManager.isAuthorized
    }

    // MARK: - Init

    init(
        repository: AttendanceRepositoryProtocol,
        locationManager: LocationManager
    ) {
        self.repository = repository
        self.locationManager = locationManager
    }

    // MARK: - Function

    /// GPS 기반 출석 요청 (pending 상태로 서버 전송)
    /// - throws: LocationError.notAuthorized, LocationError.locationFailed, DomainError.attendanceOutOfRange
    func requestGPSAttendance(sessionId: SessionID, userId: UserID) async throws -> Attendance {
        // 위치 권한 검증
        guard locationManager.isAuthorized else {
            throw LocationError.notAuthorized
        }

        // 현재 위치 조회
        guard let coordinate = locationManager.currentCoordinate else {
            throw LocationError.locationFailed("현재 위치를 가져올 수 없습니다.")
        }

        // 지오펜싱 검증
        guard locationManager.isInsideGeofence else {
            throw DomainError.attendanceOutOfRange
        }

        // 서버에 출석 요청 (pending 상태)
        let request = CreateAttendanceRequest(
            sessionId: sessionId,
            userId: userId,
            type: .gps,
            coordinate: coordinate,
            reason: nil
        )

        return try await repository.createAttendance(request: request)
    }

    /// 지각 사유 제출
    /// - throws: DomainError.attendanceReasonRequired
    func submitLateReason(
        sessionId: SessionID,
        userId: UserID,
        reason: String
    ) async throws -> Attendance {
        // 사유 필수 검증
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.attendanceReasonRequired
        }

        // 서버에 지각 사유 제출
        let request = CreateAttendanceRequest(
            sessionId: sessionId,
            userId: userId,
            type: .reason,
            coordinate: nil,
            reason: reason
        )

        return try await repository.createAttendance(request: request)
    }

    /// 불참 사유 제출
    /// - throws: DomainError.attendanceReasonRequired
    func submitAbsentReason(
        sessionId: SessionID,
        userId: UserID,
        reason: String
    ) async throws -> Attendance {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.attendanceReasonRequired
        }

        let request = CreateAttendanceRequest(
            sessionId: sessionId,
            userId: userId,
            type: .reason,
            coordinate: nil,
            reason: reason
        )

        return try await repository.createAttendance(request: request)
    }

    /// 출석 가능 시간 내인지 확인
    func isWithinAttendanceTime(session: Session) -> Bool {
        let now = Date()
        let threshold = TimeInterval(AttendancePolicy.lateThresholdMinutes * 60)
        let startWindow = session.startTime.addingTimeInterval(-threshold)
        let endWindow = session.endTime.addingTimeInterval(threshold)

        return now >= startWindow && now <= endWindow
    }
}
