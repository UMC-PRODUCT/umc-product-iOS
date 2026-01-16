//
//  MockChallengerAttendanceUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation

#if DEBUG
/// 테스트용 Mock UseCase - 다양한 시나리오 시뮬레이션
@Observable
final class MockChallengerAttendanceUseCase: ChallengerAttendanceUseCaseProtocol {

    // MARK: - Configurable State

    /// 지오펜스 내부 여부 (테스트용)
    var mockIsInsideGeofence: Bool = true

    /// 위치 권한 여부 (테스트용)
    var mockIsLocationAuthorized: Bool = true

    /// 시뮬레이션할 시간대 (nil이면 실제 계산)
    var mockTimeWindow: AttendanceTimeWindow?

    /// 에러 시뮬레이션 (nil이면 성공)
    var mockError: Error?

    /// 응답 지연 시간 (초)
    var responseDelay: TimeInterval = 1.0

    /// 자동 승인 시뮬레이션 (초, nil이면 비활성화)
    var autoApproveDelay: TimeInterval? = 2.0

    // MARK: - Protocol Properties

    var isInsideGeofence: Bool { mockIsInsideGeofence }
    var isLocationAuthorized: Bool { mockIsLocationAuthorized }

    // MARK: - Protocol Methods

    func requestGPSAttendance(sessionId: SessionID, userId: UserID) async throws -> Attendance {
        // 응답 지연 시뮬레이션
        try await Task.sleep(for: .seconds(responseDelay))

        // 에러 시뮬레이션
        if let error = mockError {
            throw error
        }

        // 성공 응답
        return Attendance(
            sessionId: sessionId,
            userId: userId,
            type: .gps,
            status: .pending,
            locationVerification: .init(
                isVerified: true,
                coordinate: .init(latitude: 37.582967, longitude: 127.010527),
                address: .init(fullAddress: "한성대학교", city: "서울시", district: "성북구"),
                verifiedAt: .now
            ),
            reason: nil
        )
    }

    func submitLateReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance {
        try await Task.sleep(for: .seconds(responseDelay))

        if let error = mockError {
            throw error
        }

        return Attendance(
            sessionId: sessionId,
            userId: userId,
            type: .reason,
            status: .pending,
            locationVerification: nil,
            reason: reason
        )
    }

    func submitAbsentReason(sessionId: SessionID, userId: UserID, reason: String) async throws -> Attendance {
        try await Task.sleep(for: .seconds(responseDelay))

        return Attendance(
            sessionId: sessionId,
            userId: userId,
            type: .reason,
            status: .pending,
            locationVerification: nil,
            reason: reason
        )
    }

    func isWithinAttendanceTime(session: Session) -> AttendanceTimeWindow {
        // Mock 설정이 있으면 그 값 사용
        if let mockWindow = mockTimeWindow {
            return mockWindow
        }

        // 실제 계산
        let now = Date()
        let onTimeThreshold = TimeInterval(AttendancePolicy.onTimeThresholdMinutes * 60)
        let lateThreshold = TimeInterval(AttendancePolicy.lateThresholdMinutes * 60)
        let startTime = session.startTime

        if now < startTime.addingTimeInterval(-onTimeThreshold) {
            return .tooEarly
        }
        if now <= startTime.addingTimeInterval(onTimeThreshold) {
            return .onTime
        }
        if now <= startTime.addingTimeInterval(lateThreshold) {
            return .lateWindow
        }
        return .expired
    }

    func getAddressToCurrentLocation() async throws -> String {
        return "Mock 주소 - 서울시 성북구 한성대학교"
    }
}
#endif
