//
//  ServerDateTimeConverterTests.swift
//  AppProductTests
//
//  Created by Codex on 3/8/26.
//

import XCTest
@testable import AppProduct

final class ServerDateTimeConverterTests: XCTestCase {

    func test_toUTCDateTimeString_서울시간을_Z_포함_UTC로_변환한다() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 3,
            day: 8,
            hour: 12,
            minute: 44,
            second: 56,
            nanosecond: 236_000_000
        )

        let date = try XCTUnwrap(calendar.date(from: components))

        XCTAssertEqual(
            ServerDateTimeConverter.toUTCDateTimeString(date),
            "2026-03-08T03:44:56.236Z"
        )
    }

    func test_parseUTCDateTime_오프셋_포함_ISO8601을_정상_파싱한다() throws {
        let date = try XCTUnwrap(
            ServerDateTimeConverter.parseUTCDateTime("2026-03-08T12:44:56.236+0900")
        )

        XCTAssertEqual(
            ServerDateTimeConverter.toUTCDateTimeString(date),
            "2026-03-08T03:44:56.236Z"
        )
    }
}
