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

    private enum CodingKeys: String, CodingKey {
        case scheduleId
        case name
        case startsAt
        case endsAt
        case status
        case dDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scheduleId = try container.decodeIntFlexibleIfPresent(forKey: .scheduleId) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        startsAt = try container.decodeIfPresent(String.self, forKey: .startsAt) ?? ""
        endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        dDay = try container.decodeIntFlexibleIfPresent(forKey: .dDay) ?? 0
    }
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
        let noTimezoneFormatter = DateFormatter()
        noTimezoneFormatter.locale = Locale(identifier: "en_US_POSIX")
        noTimezoneFormatter.timeZone = .current
        noTimezoneFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let noTimezoneFractionFormatter = DateFormatter()
        noTimezoneFractionFormatter.locale = Locale(identifier: "en_US_POSIX")
        noTimezoneFractionFormatter.timeZone = .current
        noTimezoneFractionFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"

        return formatterWithFraction.date(from: string)
            ?? formatter.date(from: string)
            ?? noTimezoneFractionFormatter.date(from: string)
            ?? noTimezoneFormatter.date(from: string)
            ?? .now
    }
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }
}
