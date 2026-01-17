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
    private let locationManager: LocationManager = .shared

    // MARK: - Computed Property

    var isInsideGeofence: Bool {
        locationManager.isInsideGeofence
    }

    var isLocationAuthorized: Bool {
        locationManager.isAuthorized
    }

    // MARK: - Init

    init(repository: AttendanceRepositoryProtocol) {
        self.repository = repository
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

    /// 현재 시간이 어느 출석 시간대에 속하는지 확인
    func isWithinAttendanceTime(info: SessionInfo) -> AttendanceTimeWindow {
        let now = Date()
        let onTimeThreshold = TimeInterval(AttendancePolicy.onTimeThresholdMinutes * 60)
        let lateThreshold = TimeInterval(AttendancePolicy.lateThresholdMinutes * 60)
        let startTime = info.startTime

        // 세션 시작 - threshold 이전이면 너무 이름
        if now < startTime.addingTimeInterval(-onTimeThreshold) {
            return .tooEarly
        }

        // 세션 시작 ± threshold 내이면 정시 출석 가능
        if now <= startTime.addingTimeInterval(onTimeThreshold) {
            return .onTime
        }

        // 세션 시작 + lateThreshold 내이면 지각 시간대
        if now <= startTime.addingTimeInterval(lateThreshold) {
            return .lateWindow
        }

        // 그 이후는 마감
        return .expired
    }

    /// 지오코딩
    func getAddressToCurrentLocation() async throws -> String {
        guard let coordinate = locationManager.currentCoordinate else {
            throw LocationError.locationFailed("주소를 찾을 수 없습니다.")
        }
        return try await locationManager.reverseGeocode(coordinate: coordinate)
    }
}
