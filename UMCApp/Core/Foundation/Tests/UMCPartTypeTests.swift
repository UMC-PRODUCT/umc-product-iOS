//
//  UMCPartTypeTests.swift
//  UMCFoundationTests
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation
import Testing
@testable import UMCFoundation

@Suite("UMCPartType — 서버 파트 문자열 계약 (#1351)")
struct UMCPartTypeTests {

    // MARK: - Property

    /// 서버 `ChallengerPart` 가 내려주는 전체 값. 레거시 5종(`WEB`·`ANDROID`·`IOS`·
    /// `NODEJS`·`SPRINGBOOT`)은 신규 발급이 없을 뿐 구 기수 기록에 그대로 남아 있어
    /// 지우면 지난 기수가 안 읽힌다.
    private static let apiContract: [(apiValue: String, part: UMCPartType)] = [
        ("ADMIN", .admin),
        ("PLAN", .pm),
        ("DESIGN", .design),
        ("WEB", .front(type: .web)),
        ("ANDROID", .front(type: .android)),
        ("IOS", .front(type: .ios)),
        ("NODEJS", .server(type: .node)),
        ("SPRINGBOOT", .server(type: .spring)),
        ("WEB_PRODUCT_ENGINEER", .webProductEngineer),
        ("MOBILE_PRODUCT_ENGINEER", .mobileProductEngineer),
    ]

    // MARK: - Function

    /// 이 왕복이 깨지면 해당 파트 챌린저가 화면마다 다른 파트로 **조용히** 바뀐다 —
    /// 호출부가 `init?(apiValue:)` 의 `nil` 을 `.front(.ios)`·`.pm`·`.admin` 으로
    /// 대체하기 때문이다 (#1351).
    @Test("서버 파트 문자열과 enum 이 1:1 로 왕복한다", arguments: apiContract)
    func apiValueRoundTrips(contract: (apiValue: String, part: UMCPartType)) {
        #expect(UMCPartType(apiValue: contract.apiValue) == contract.part)
        #expect(contract.part.apiValue == contract.apiValue)
    }

    @Test("모르는 파트 문자열은 여전히 nil 이다", arguments: ["RUST", "", "ios", "PLAN "])
    func unknownApiValueReturnsNil(raw: String) {
        #expect(UMCPartType(apiValue: raw) == nil)
    }

    /// `allCases` 는 스터디 그룹 생성의 파트 선택지를 그대로 만든다
    /// (`OperatorStudyGroupCreateView`). 신규 파트가 빠지면 11기 스터디를 만들 수 없다.
    @Test("파트 선택지(allCases)에 신규 두 파트가 들어 있고 운영진은 빠진다")
    func allCasesContainsNewPartsWithoutAdmin() {
        #expect(UMCPartType.allCases.contains(.webProductEngineer))
        #expect(UMCPartType.allCases.contains(.mobileProductEngineer))
        #expect(!UMCPartType.allCases.contains(.admin))
        #expect(Set(UMCPartType.allCases).count == UMCPartType.allCases.count)
    }

    @Test("신규 두 파트가 표시명·아이콘·정렬 순서를 갖는다")
    func newPartsHaveDisplayMetadata() {
        #expect(UMCPartType.webProductEngineer.name == "웹 프로덕트 엔지니어")
        #expect(UMCPartType.mobileProductEngineer.name == "모바일 프로덕트 엔지니어")
        #expect(!UMCPartType.webProductEngineer.icon.isEmpty)
        #expect(!UMCPartType.mobileProductEngineer.icon.isEmpty)
        #expect(UMCPartType.webProductEngineer.sortOrder
            > UMCPartType.server(type: .node).sortOrder)
        #expect(UMCPartType.mobileProductEngineer.sortOrder
            > UMCPartType.webProductEngineer.sortOrder)
    }

    /// 정렬 순서가 겹치면 파트 목록 순서가 비결정적으로 흔들린다.
    @Test("파트마다 정렬 순서가 서로 다르다")
    func sortOrdersAreDistinct() {
        let parts = Self.apiContract.map(\.part)
        #expect(Set(parts.map(\.sortOrder)).count == parts.count)
    }

    /// `Codable` 은 `apiValue` 를 그대로 싣는다 — 명함 교환 페이로드가 이 경로를 탄다.
    @Test("Codable 왕복이 서버 문자열을 보존한다", arguments: apiContract)
    func codableRoundTrips(contract: (apiValue: String, part: UMCPartType)) throws {
        let encoded = try JSONEncoder().encode(contract.part)

        #expect(String(data: encoded, encoding: .utf8) == "\"\(contract.apiValue)\"")
        #expect(try JSONDecoder().decode(UMCPartType.self, from: encoded) == contract.part)
    }
}
