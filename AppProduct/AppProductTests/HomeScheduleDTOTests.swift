//
//  HomeScheduleDTOTests.swift
//  AppProductTests
//
//  Created by Codex on 3/8/26.
//

import XCTest
@testable import AppProduct

final class HomeScheduleDTOTests: XCTestCase {

    func test_homeScheduleResponseDTO_startTime_endTime_키도_디코딩한다() throws {
        let data = try XCTUnwrap(
            """
            {
              "scheduleId": 395,
              "name": "운영 회의",
              "startTime": "2026-03-08T03:44:56.236Z",
              "endTime": "2026-03-08T05:15:56.236Z",
              "status": "참여 예정",
              "dDay": 0
            }
            """.data(using: .utf8)
        )

        let dto = try JSONDecoder().decode(HomeScheduleResponseDTO.self, from: data)

        XCTAssertEqual(dto.startsAt, "2026-03-08T03:44:56.236Z")
        XCTAssertEqual(dto.endsAt, "2026-03-08T05:15:56.236Z")
    }

    func test_scheduleDetailDTO_startTime_endTime_키도_디코딩한다() throws {
        let data = try XCTUnwrap(
            """
            {
              "scheduleId": 395,
              "name": "운영 회의",
              "description": "다음 스프린트 조율",
              "tags": ["운영"],
              "startTime": "2026-03-08T03:44:56.236Z",
              "endTime": "2026-03-08T05:15:56.236Z",
              "isAllDay": false,
              "locationName": "UMC 라운지",
              "latitude": 37.5665,
              "longitude": 126.9780,
              "status": "참여 예정",
              "dDay": 0,
              "requiresAttendanceApproval": false
            }
            """.data(using: .utf8)
        )

        let dto = try JSONDecoder().decode(ScheduleDetailDTO.self, from: data)

        XCTAssertEqual(dto.startsAt, "2026-03-08T03:44:56.236Z")
        XCTAssertEqual(dto.endsAt, "2026-03-08T05:15:56.236Z")
    }
}
