//
//  MockAttendanceRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import Foundation

#if DEBUG
/// Preview 및 테스트용 Mock AttendanceRepository
///
/// 실제 네트워크 요청 없이 더미 데이터를 반환합니다.
final class MockAttendanceRepository: AttendanceRepositoryProtocol {

    // MARK: - Mock Data

    private let mockAttendance: Attendance

    init(mockAttendance: Attendance? = nil) {
        self.mockAttendance = mockAttendance ?? Self.defaultMockAttendance
    }

    // MARK: - Protocol Methods

    func createAttendance(request: CreateAttendanceRequest) async throws -> Attendance {
        // 사유 기반 출석은 승인 대기 상태로 반환
        let status: AttendanceStatus = request.type == .reason
            ? .pendingApproval
            : .beforeAttendance

        return Attendance(
            sessionId: request.sessionId,
            userId: request.userId,
            type: request.type,
            status: status,
            locationVerification: request.coordinate.map {
                LocationVerification(
                    isVerified: true,
                    coordinate: $0,
                    address: .init(fullAddress: "Mock 주소", city: "서울시", district: "성북구"),
                    verifiedAt: .now
                )
            },
            reason: request.reason
        )
    }

    func updateAttendanceStatus(
        attendanceId: AttendanceID,
        status: AttendanceStatus,
        verification: LocationVerification?
    ) async throws -> Attendance {
        return Attendance(
            sessionId: mockAttendance.sessionId,
            userId: mockAttendance.userId,
            type: mockAttendance.type,
            status: status,
            locationVerification: verification ?? mockAttendance.locationVerification,
            reason: mockAttendance.reason
        )
    }

    func fetchPendingAttendances(sessionId: SessionID) async throws -> [Attendance] {
        return [mockAttendance]
    }

    func fetchAttendances(sessionId: SessionID) async throws -> [Attendance] {
        return [mockAttendance]
    }

    func fetchUserAttendanceHistory(userId: UserID) async throws -> [Attendance] {
        return [mockAttendance]
    }
}

// MARK: - Default Mock Data

extension MockAttendanceRepository {
    static let defaultMockAttendance = Attendance(
        sessionId: SessionID(value: "mock_session"),
        userId: UserID(value: "mock_user"),
        type: .gps,
        status: .beforeAttendance,
        locationVerification: .init(
            isVerified: true,
            coordinate: .init(latitude: 37.582967, longitude: 127.010527),
            address: .init(fullAddress: "한성대학교", city: "서울시", district: "성북구"),
            verifiedAt: .now
        ),
        reason: nil
    )
}
#endif
