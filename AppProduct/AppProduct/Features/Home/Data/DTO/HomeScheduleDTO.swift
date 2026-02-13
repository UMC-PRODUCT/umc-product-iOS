//
//  HomeScheduleDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 월별 내 일정 조회 Response DTO
///
/// `GET /api/v1/schedules/my-list?year=&month=`
struct HomeScheduleResponseDTO: Codable {
    /// 일정 고유 ID
    let scheduleId: Int
    /// 일정 이름
    let name: String
    /// 시작 시각 (ISO 8601 형식)
    let startsAt: String
    /// 종료 시각 (ISO 8601 형식)
    let endsAt: String
    /// 참여 상태 (예: "참여 예정")
    let status: String
    /// D-Day 값 (음수: 지남, 양수: 남음)
    let dDay: Int
}

// MARK: - toDomain

extension HomeScheduleResponseDTO {

    /// DTO → ScheduleData 변환
    func toScheduleData() -> ScheduleData {
        let startsDate = Self.parseISO8601(startsAt)
        let endsDate = Self.parseISO8601(endsAt)
        return ScheduleData(
            scheduleId: scheduleId,
            title: name,
            startsAt: startsDate,
            endsAt: endsDate,
            status: status,
            dDay: dDay
        )
    }

    /// ISO 8601 문자열 → Date 변환 (fractionalSeconds 우선 시도)
    private static func parseISO8601(_ string: String) -> Date {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return formatterWithFraction.date(from: string)
            ?? formatter.date(from: string)
            ?? .now
    }
}
