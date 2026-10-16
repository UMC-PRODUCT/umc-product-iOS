//
//  MissionTypeTests.swift
//  ActivityDomainTests
//
//  Created by jaewon Lee on 5/17/26.
//

import Foundation
import Testing
@testable import ActivityDomain

@Suite("MissionType — 서버 contract (도메인 규칙)")
struct MissionTypeTests {

    // MARK: - init(rawValue:) (서버 contract)

    @Test(
        "init(rawValue:) 는 대소문자 무관하게 서버 contract 문자열을 enum 으로 변환한다",
        arguments: [
            ("LINK", MissionType.link),
            ("link", MissionType.link),
            ("Link", MissionType.link),
            ("MEMO", MissionType.memo),
            ("memo", MissionType.memo),
            ("PLAIN", MissionType.plain),
            ("plain", MissionType.plain)
        ]
    )
    func initFromServerStringCaseInsensitive(rawValue: String, expected: MissionType) {
        #expect(MissionType(rawValue: rawValue) == expected)
    }

    @Test(
        "init(rawValue:) 는 알 수 없는 문자열에 대해 .unknown 으로 fallback 한다",
        arguments: ["", "FOO", "submitted"]
    )
    func initFromUnknownStringFallsBackToUnknown(rawValue: String) {
        #expect(MissionType(rawValue: rawValue) == .unknown)
    }
}
