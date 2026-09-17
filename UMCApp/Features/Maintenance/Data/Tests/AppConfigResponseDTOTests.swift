//
//  AppConfigResponseDTOTests.swift
//  MaintenanceDataTests
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation
import MaintenanceDomain
import Testing
@testable import MaintenanceData

// MARK: - Helpers

private func decode(_ json: String) throws -> AppConfigResponseDTO {
    try JSONDecoder().decode(AppConfigResponseDTO.self, from: Data(json.utf8))
}

// MARK: - Tests

@Suite("AppConfigResponseDTO — 원격 설정 파일 디코딩")
struct AppConfigResponseDTOTests {

    @Test("문자열 버전도 읽고, 모르는 모양은 unknown으로 받는다")
    func decodesStringVersionAndUnknownTemplate() throws {
        let dto = try decode("""
        {
          "version": "1",
          "minimumVersion": " 2.3.0 ",
          "notices": [
            { "screen": "home", "enabled": true, "template": "BANNER",
              "title": "안내", "body": "본문" },
            { "screen": "ALL", "enabled": true, "template": "BLOCKING",
              "title": "점검", "body": "점검 중", "until": "2026-09-17" }
          ]
        }
        """)

        let notices = dto.toNotices()
        #expect(dto.toMinimumSupportedVersion() == "2.3.0")
        #expect(notices.map(\.template) == [.unknown, .blocking])
        #expect(notices.last?.until == "2026-09-17")
    }

    @Test("최소 버전이 비어 있으면 업데이트를 요구하지 않는다")
    func emptyMinimumVersionIsNil() throws {
        let dto = try decode(#"{ "version": 1, "minimumVersion": "", "notices": [] }"#)

        #expect(dto.toMinimumSupportedVersion() == nil)
    }

    @Test("모르는 형식 버전이면 전부 비활성으로 본다")
    func unsupportedVersionIsInactive() throws {
        let dto = try decode("""
        { "version": 2, "minimumVersion": "9.9.9",
          "notices": [ { "screen": "ALL", "enabled": true, "template": "BLOCKING",
                         "title": "점검", "body": "점검 중" } ] }
        """)

        #expect(dto.toMinimumSupportedVersion() == nil)
        #expect(dto.toNotices().isEmpty)
    }

    @Test("필수 값이 빠진 안내는 버린다")
    func dropsIncompleteNotice() throws {
        let dto = try decode("""
        { "version": 1,
          "notices": [ { "screen": "home", "enabled": true, "template": "INFO", "title": "" } ] }
        """)

        #expect(dto.toNotices().isEmpty)
    }
}
