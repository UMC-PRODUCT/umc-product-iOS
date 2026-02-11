//
//  HomeScheduleDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

struct HomeScheduleDTO: Decodable {
    let scheduleId: Int
    let name: String
    let status: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let locationName: String
    let totalCount: Int
    let presentCount: Int
    let pendingCount: Int
    let attendanceRate: Int

    enum CodingKeys: String, CodingKey {
        case scheduleId, name, status, date, startTime, endTime
        case locationName, totalCount, presentCount, pendingCount, attendanceRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.scheduleId = try container.decode(Int.self, forKey: .scheduleId)
        self.name = try container.decode(String.self, forKey: .name)
        self.status = try container.decode(String.self, forKey: .status)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.totalCount = try container.decode(Int.self, forKey: .totalCount)
        self.presentCount = try container.decode(Int.self, forKey: .presentCount)
        self.pendingCount = try container.decode(Int.self, forKey: .pendingCount)
        self.attendanceRate = try container.decode(Int.self, forKey: .attendanceRate)

        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        self.date = try Self.decodeDate(from: container, forKey: .date,
                                        formatters: [formatterWithFraction, formatter])
        self.startTime = try Self.decodeDate(from: container, forKey: .startTime,
                                             formatters: [formatterWithFraction, formatter])
        self.endTime = try Self.decodeDate(from: container, forKey: .endTime,
                                           formatters: [formatterWithFraction, formatter])
    }

    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys,
        formatters: [ISO8601DateFormatter]
    ) throws -> Date {
        let string = try container.decode(String.self, forKey: key)
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: container,
            debugDescription: "Invalid ISO8601 date string for \(key.stringValue): \(string)"
        )
    }
}
