//
//  MockSessionRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/22/26.
//

import Foundation

#if DEBUG
/// Preview 및 테스트용 Mock SessionRepository
///
/// 실제 네트워크 요청 없이 더미 세션 목록을 반환합니다.
final class MockSessionRepository: SessionRepositoryProtocol {

    // MARK: - Mock Data

    private let mockSessions: [SessionInfo]

    init(mockSessions: [SessionInfo]? = nil) {
        self.mockSessions = mockSessions ?? Self.defaultMockSessions
    }

    // MARK: - Protocol Methods

    @MainActor
    func fetchSessionList() async throws -> [Session] {
        return mockSessions.map { Session(info: $0) }
    }
}

// MARK: - Default Mock Data

extension MockSessionRepository {

    /// 한성대학교 좌표
    private static let hansungCoordinate = Coordinate(latitude: 37.582967, longitude: 127.010527)
    /// 공덕 창업허브 좌표
    private static let gongdeokCoordinate = Coordinate(latitude: 37.5445, longitude: 126.9519)

    /// 출석 가능한 세션 (PM DAY + 스터디 8주차)
    static let defaultMockSessions: [SessionInfo] = [
        // PM DAY (공덕 창업허브) - 출석 가능
        SessionInfo(
            sessionId: SessionID(value: "pm_day"),
            icon: .Activity.profile,
            title: "PM DAY",
            week: 0,
            startTime: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now)!,
            location: gongdeokCoordinate
        ),
        // 스터디 8주차 (한성대학교) - 출석 가능
        SessionInfo(
            sessionId: SessionID(value: "iOS_8"),
            icon: .Activity.profile,
            title: "좋은 컴포넌트 설계란 무엇일까",
            week: 8,
            startTime: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
            endTime: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
            location: hansungCoordinate
        )
    ]
}
#endif
