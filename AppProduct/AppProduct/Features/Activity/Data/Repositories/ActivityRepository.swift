//
//  ActivityRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation
import SwiftUI

/// Activity Repository 실제 구현체
///
/// 출석 가능 일정 API를 통해 세션 목록을 제공합니다.
final class ActivityRepository: ActivityRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let attendanceRepository: ChallengerAttendanceRepositoryProtocol

    // MARK: - Init

    init(attendanceRepository: ChallengerAttendanceRepositoryProtocol) {
        self.attendanceRepository = attendanceRepository
    }

    // MARK: - Function

    @MainActor
    func fetchSessions() async throws -> [Session] {
        let schedules = try await attendanceRepository
            .getAvailableSchedules()
        return schedules.map { schedule in
            let startTime = Self.parseTime(schedule.startTime)
            var endTime = Self.parseTime(schedule.endTime)
            // FIXME: 자정 넘김 휴리스틱 — 서버가 ISO 8601 datetime 반환 시 제거 (#304) - [25.02.18] 이재원
            if endTime < startTime {
                endTime = Calendar.current.date(
                    byAdding: .day, value: 1, to: endTime
                ) ?? endTime
            }
            return Session(
                info: SessionInfo(
                    sessionId: SessionID(
                        value: String(schedule.scheduleId)
                    ),
                    // TODO: 서버 API에 icon/week/location 필드 추가 후 하드코딩 제거 예정
                    icon: .Activity.profile,
                    title: schedule.scheduleName,
                    week: 0,
                    startTime: startTime,
                    endTime: endTime,
                    location: Coordinate(
                        latitude: 37.582967,
                        longitude: 127.010527
                    )
                ),
                initialAttendance: Self.mapAttendance(
                    schedule: schedule
                )
            )
        }
    }

    func fetchCurrentUserId() async throws -> UserID {
        let memberId = UserDefaults.standard.integer(
            forKey: AppStorageKey.memberId
        )
        return UserID(value: String(memberId))
    }

    // MARK: - Private Helper

    /// 시간 문자열 → 오늘 날짜 기준 Date 변환
    ///
    /// 지원 형식: ISO 8601, "HH:mm:ss", "HH:mm"
    private static func parseTime(_ timeString: String) -> Date {
        // 서버 UTC 시간(ISO 8601 또는 HH:mm:ss/HH:mm) 파싱
        ServerDateTimeConverter.parseUTCDateTimeOrTime(timeString) ?? Date()
    }

    /// AvailableAttendanceSchedule의 status → 초기 Attendance 변환
    private static func mapAttendance(
        schedule: AvailableAttendanceSchedule
    ) -> Attendance? {
        switch schedule.status {
        case .beforeAttendance, .pendingApproval:
            return nil
        case .present, .late, .absent:
            return Attendance(
                sessionId: SessionID(
                    value: String(schedule.scheduleId)
                ),
                userId: UserID(value: ""),
                type: schedule.locationVerified ? .gps : .reason,
                status: schedule.status,
                locationVerification: nil,
                reason: nil
            )
        }
    }
}
