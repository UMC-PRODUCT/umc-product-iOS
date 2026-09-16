//
//  MemberManagementProfileDTOTests.swift
//  ActivityDataTests
//
//  Created by jaewon Lee on 6/28/26.
//

import Testing
import Foundation
import UMCFoundation
@testable import ActivityData

// MARK: - Suite: 멤버 관리 프로필 디코딩 계약

@Suite("MemberManagementProfileDTO — 디코딩 매핑 (서버 contract)")
struct MemberManagementProfileDTODecodingTests {

    private func decode(_ json: String) throws -> MemberManagementProfileDTO {
        try JSONDecoder().decode(
            MemberManagementProfileDTO.self,
            from: Data(json.utf8)
        )
    }

    @Test("숫자/문자 혼재 식별자를 String 으로 통일하고 profileImageLink 를 매핑한다")
    func decodesIdentifiersAsStringAndMapsImageKey() throws {
        let json = """
        {
          "id": 100, "name": "홍길동", "nickname": "길동", "schoolName": "한성대",
          "profileImageLink": "https://img/1.png",
          "roles": [{ "challengerId": 7, "roleType": "SCHOOL_PART_LEADER" }],
          "challengerRecords": [
            {
              "challengerId": "C100", "memberId": 100, "gisu": 7, "gisuId": 70,
              "part": "IOS", "challengerPoints": [], "points": []
            }
          ]
        }
        """

        let dto = try decode(json)

        #expect(dto.id == "100")
        #expect(dto.profileImageURL == "https://img/1.png")
        #expect(dto.roles.first?.challengerId == "7")
        #expect(dto.roles.first?.roleType == .schoolPartLeader)
        #expect(dto.challengerRecords.first?.memberId == "100")
        #expect(dto.challengerRecords.first?.gisuId == "70")
        #expect(dto.challengerRecords.first?.gisu == 7)   // 기수 표시 수치는 Int 유지
    }

    @Test("roleType 이 미지의 값이면 challenger 로 폴백한다")
    func unknownRoleTypeFallsBackToChallenger() throws {
        let json = """
        {
          "id": "1", "name": "", "nickname": "", "schoolName": "",
          "roles": [{ "challengerId": null, "roleType": "BRAND_NEW_ROLE" }],
          "challengerRecords": []
        }
        """

        let dto = try decode(json)

        #expect(dto.roles.first?.roleType == .challenger)
        #expect(dto.roles.first?.challengerId == nil)
    }

    @Test("resolvedPoints — challengerPoints 가 비면 points 폴백을 사용한다")
    func resolvedPointsFallsBackToPoints() throws {
        let json = """
        {
          "id": "1", "name": "", "nickname": "", "schoolName": "",
          "roles": [],
          "challengerRecords": [
            {
              "challengerId": "C1", "memberId": "1", "gisu": 7, "gisuId": "70",
              "part": "IOS", "challengerPoints": [],
              "points": [
                {
                  "id": "9", "pointType": "STUDY_LATE", "point": -2,
                  "description": "지각", "createdAt": "2026-06-01T09:00:00.000Z"
                }
              ]
            }
          ]
        }
        """

        let dto = try decode(json)
        let record = try #require(dto.challengerRecords.first)

        #expect(record.challengerPoints.isEmpty)
        #expect(record.resolvedPoints.count == 1)
        #expect(record.resolvedPoints.first?.id == "9")
        #expect(record.resolvedPoints.first?.point == -2)
    }

    @Test("resolvedPoints — challengerPoints 가 있으면 그것을 우선한다")
    func resolvedPointsPrefersChallengerPoints() throws {
        let json = """
        {
          "id": "1", "name": "", "nickname": "", "schoolName": "",
          "roles": [],
          "challengerRecords": [
            {
              "challengerId": "C1", "memberId": "1", "gisu": 7, "gisuId": "70",
              "part": "IOS",
              "challengerPoints": [
                {
                  "id": "1", "pointType": "BLOG_CHALLENGE", "point": 3,
                  "description": "", "createdAt": "2026-06-01T09:00:00.000Z"
                }
              ],
              "points": [
                {
                  "id": "2", "pointType": "STUDY_LATE", "point": -2,
                  "description": "", "createdAt": "2026-06-01T09:00:00.000Z"
                }
              ]
            }
          ]
        }
        """

        let dto = try decode(json)
        let record = try #require(dto.challengerRecords.first)

        #expect(record.resolvedPoints.map(\.id) == ["1"])
    }

    // MARK: - infra / part null (#1351 서버 Part 체계 개편)

    /// 같은 `GET /api/v1/member/profile/{memberId}` 응답이라 프로필 DTO 와 폴백 규칙이
    /// 같아야 한다 — 키 없음·`null` 은 `false`.
    @Test("infra 를 유연하게 디코딩하고 키가 없거나 null 이면 false 로 폴백한다")
    func decodesInfraFlag() throws {
        let cases: [(label: String, raw: String?, expected: Bool)] = [
            ("키 없음", nil, false),
            ("null", "null", false),
            ("true", "true", true),
            ("false", "false", false),
            ("정수 1", "1", true),
            ("문자열 true", "\"true\"", true),
        ]

        for testCase in cases {
            let infraEntry = testCase.raw.map { ", \"infra\": \($0)" } ?? ""
            let json = """
            {
              "id": 100, "name": "홍길동", "nickname": "길동", "schoolName": "한성대",
              "roles": [],
              "challengerRecords": [
                {
                  "challengerId": 1, "memberId": 100, "gisu": 11, "gisuId": 70,
                  "part": "MOBILE_PRODUCT_ENGINEER"\(infraEntry)
                }
              ]
            }
            """

            let record = try #require(decode(json).challengerRecords.first)

            #expect(record.infra == testCase.expected, "\(testCase.label)")
        }
    }

    /// 비수강 운영진 레코드는 `part` 가 `null` 로 온다 — 디코딩을 깨지 않고 빈 문자열로 남긴다.
    @Test("part 가 null 이어도 디코딩되고 빈 문자열로 남는다")
    func decodesNullPartAsEmptyString() throws {
        let json = """
        {
          "id": 100, "name": "홍길동", "nickname": "길동", "schoolName": "한성대",
          "roles": [],
          "challengerRecords": [
            {
              "challengerId": 1, "memberId": 100, "gisu": 11, "gisuId": 70,
              "part": null
            }
          ]
        }
        """

        let record = try #require(decode(json).challengerRecords.first)

        #expect(record.part.isEmpty)
        #expect(record.infra == false)
    }

    /// 신규 파트 문자열이 그대로 보존돼야 하류에서 `UMCPartType` 으로 읽힌다.
    @Test(
        "신규 파트 문자열이 UMCPartType 으로 해석된다",
        arguments: [
            ("WEB_PRODUCT_ENGINEER", UMCPartType.webProductEngineer),
            ("MOBILE_PRODUCT_ENGINEER", UMCPartType.mobileProductEngineer)
        ]
    )
    func resolvesNewPartStrings(apiValue: String, expected: UMCPartType) throws {
        let json = """
        {
          "id": 100, "name": "홍길동", "nickname": "길동", "schoolName": "한성대",
          "roles": [],
          "challengerRecords": [
            {
              "challengerId": 1, "memberId": 100, "gisu": 11, "gisuId": 70,
              "part": "\(apiValue)", "infra": true
            }
          ]
        }
        """

        let record = try #require(decode(json).challengerRecords.first)

        #expect(UMCPartType(apiValue: record.part) == expected)
        #expect(record.infra)
    }
}
