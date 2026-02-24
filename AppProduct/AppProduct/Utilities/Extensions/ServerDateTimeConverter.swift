//
//  ServerDateTimeConverter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

enum ServerDateTimeConverter {

    // MARK: - TimeZone

    static let utcTimeZone: TimeZone = .init(secondsFromGMT: 0) ?? .current
    static let kstTimeZone: TimeZone = .init(identifier: "Asia/Seoul") ?? .current

    // MARK: - Function

    static func parseUTCDateTime(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }

        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        if let date = formatterWithFraction.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }

        for format in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        ] {
            let fallback = DateFormatter()
            fallback.locale = Locale(identifier: "en_US_POSIX")
            fallback.timeZone = utcTimeZone
            fallback.dateFormat = format
            if let date = fallback.date(from: value) {
                return date
            }
        }

        return nil
    }

    static func parseUTCDateTimeOrTime(
        _ value: String,
        utcDate: String? = nil
    ) -> Date? {
        if let date = parseUTCDateTime(value) {
            return date
        }
        return parseUTCTime(value, utcDate: utcDate)
    }

    static func parseUTCTime(
        _ value: String,
        utcDate: String? = nil
    ) -> Date? {
        guard !value.isEmpty else { return nil }

        let calendar = makeUTCCalendar()
        let baseDate = parseUTCDate(utcDate ?? "") ?? Date()

        for format in ["HH:mm:ss", "HH:mm"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = utcTimeZone
            formatter.dateFormat = format

            guard let time = formatter.date(from: value) else {
                continue
            }

            var components = calendar.dateComponents(
                [.year, .month, .day],
                from: baseDate
            )
            let timeComponents = calendar.dateComponents(
                [.hour, .minute, .second],
                from: time
            )
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            components.second = timeComponents.second

            if let date = calendar.date(from: components) {
                return date
            }
        }

        return nil
    }

    static func parseUTCDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }

        for format in ["yyyy-MM-dd", "yyyy.MM.dd"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = utcTimeZone
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    static func toKSTDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR_POSIX")
        formatter.timeZone = kstTimeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func toKSTTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR_POSIX")
        formatter.timeZone = kstTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Private

    private static func makeUTCCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        return calendar
    }
}
