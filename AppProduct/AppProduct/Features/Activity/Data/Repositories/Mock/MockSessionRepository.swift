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
    static let defaultMockSessions: [SessionInfo] = [
        SessionInfo(
            sessionId: SessionID(value: "iOS_1"),
            icon: .Activity.profile,
            title: "Swift 기초 문법",
            week: 1,
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
            endTime: .now,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        ),
        SessionInfo(
            sessionId: SessionID(value: "iOS_2"),
            icon: .Activity.profile,
            title: "SwiftUI 입문",
            week: 2,
            startTime: Calendar.current.date(byAdding: .day, value: 7, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 7, to: .now)!)!,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        ),
        SessionInfo(
            sessionId: SessionID(value: "iOS_3"),
            icon: .Activity.profile,
            title: "Combine 기초",
            week: 3,
            startTime: Calendar.current.date(byAdding: .day, value: 14, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 14, to: .now)!)!,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        ),
        SessionInfo(
            sessionId: SessionID(value: "iOS_4"),
            icon: .Activity.profile,
            title: "네트워킹과 Alamofire",
            week: 4,
            startTime: Calendar.current.date(byAdding: .day, value: 21, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 21, to: .now)!)!,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        ),
        SessionInfo(
            sessionId: SessionID(value: "iOS_5"),
            icon: .Activity.profile,
            title: "MVVM 아키텍처",
            week: 5,
            startTime: Calendar.current.date(byAdding: .day, value: 28, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 28, to: .now)!)!,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        ),
        SessionInfo(
            sessionId: SessionID(value: "iOS_6"),
            icon: .Activity.profile,
            title: "프로젝트 마무리",
            week: 6,
            startTime: Calendar.current.date(byAdding: .day, value: 35, to: .now)!,
            endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.date(byAdding: .day, value: 35, to: .now)!)!,
            location: Coordinate(latitude: 37.582967, longitude: 127.010527)
        )
    ]
}
#endif
