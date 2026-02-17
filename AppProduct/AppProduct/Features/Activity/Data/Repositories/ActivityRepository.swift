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
            Session(
                info: SessionInfo(
                    sessionId: SessionID(
                        value: String(schedule.scheduleId)
                    ),
                    icon: .Activity.profile,
                    title: schedule.scheduleName,
                    week: 0,
                    startTime: Self.parseTime(schedule.startTime),
                    endTime: Self.parseTime(schedule.endTime),
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
        // ISO 8601 형식 시도
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        if let date = isoFormatter.date(from: timeString) {
            return date
        }

        // "HH:mm:ss" 또는 "HH:mm" 형식 시도
        let calendar = Calendar.current
        let now = Date()
        for format in ["HH:mm:ss", "HH:mm"] {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "ko_KR")
            if let time = formatter.date(from: timeString) {
                var components = calendar.dateComponents(
                    [.year, .month, .day], from: now
                )
                let timeComponents = calendar.dateComponents(
                    [.hour, .minute, .second], from: time
                )
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                components.second = timeComponents.second
                if let date = calendar.date(from: components) {
                    return date
                }
            }
        }

        // 폴백: 현재 시간
        return Date()
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
