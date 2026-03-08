//
//  RequestDateEncodingTests.swift
//  AppProductTests
//
//  Created by euijjang on 3/8/26.
//

import XCTest
@testable import AppProduct

final class RequestDateEncodingTests: XCTestCase {

    func test_일정생성DTO는_UTC_Z형식으로_인코딩한다() throws {
        let dto = GenerateScheduleRequetDTO(
            name: "정기 모임",
            startsAt: makeSeoulDate(hour: 12, minute: 44),
            endsAt: makeSeoulDate(hour: 14, minute: 15),
            isAllDay: false,
            locationName: "UMC",
            latitude: 37.5,
            longitude: 127.0,
            description: "설명",
            participantMemberIds: [1, 2],
            tags: [.general],
            gisuId: 9,
            requiresApproval: false
        )

        let json = try encodedJSON(from: dto)

        XCTAssertEqual(json["startsAt"] as? String, "2026-03-08T03:44:56.236Z")
        XCTAssertEqual(json["endsAt"] as? String, "2026-03-08T05:15:56.236Z")
    }

    func test_일정수정DTO는_UTC_Z형식으로_인코딩한다() throws {
        let dto = UpdateScheduleRequestDTO(
            name: nil,
            startsAt: makeSeoulDate(hour: 12, minute: 44),
            endsAt: makeSeoulDate(hour: 14, minute: 15),
            isAllDay: nil,
            locationName: nil,
            latitude: nil,
            longitude: nil,
            description: nil,
            tags: nil,
            participantMemberIds: nil
        )

        let json = try encodedJSON(from: dto)

        XCTAssertEqual(json["startsAt"] as? String, "2026-03-08T03:44:56.236Z")
        XCTAssertEqual(json["endsAt"] as? String, "2026-03-08T05:15:56.236Z")
    }

    func test_스터디일정생성DTO는_UTC_Z형식으로_인코딩한다() throws {
        let dto = StudyGroupScheduleCreateRequestDTO(
            name: "스터디",
            startsAt: makeSeoulDate(hour: 12, minute: 44),
            endsAt: makeSeoulDate(hour: 14, minute: 15),
            isAllDay: false,
            locationName: "강의실",
            latitude: 37.5,
            longitude: 127.0,
            description: "자료 준비",
            tags: ["STUDY"],
            studyGroupId: 1,
            gisuId: 9,
            requiresApproval: true
        )

        let json = try encodedJSON(from: dto)

        XCTAssertEqual(json["startsAt"] as? String, "2026-03-08T03:44:56.236Z")
        XCTAssertEqual(json["endsAt"] as? String, "2026-03-08T05:15:56.236Z")
    }

    private func encodedJSON<T: Encodable>(from value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return object
    }

    private func makeSeoulDate(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: 2026,
            month: 3,
            day: 8,
            hour: hour,
            minute: minute,
            second: 56,
            nanosecond: 236_000_000
        )

        return calendar.date(from: components) ?? Date()
    }
}
