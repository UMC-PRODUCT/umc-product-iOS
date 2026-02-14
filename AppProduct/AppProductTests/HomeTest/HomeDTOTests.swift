//
//  HomeDTOTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 2/12/26.
//

import Testing
import Foundation
@testable import AppProduct

// MARK: - Home DTO Tests

@Suite("Home DTO Tests")
@MainActor
struct HomeDTOTests {

    // MARK: - ChallengerMemberDTO

    @Suite("ChallengerMemberDTO")
    @MainActor
    struct ChallengerMemberDTOTests {

        @Test("JSON_디코딩_성공")
        func JSON_디코딩_성공() throws {
            // Given
            let json = """
            {
                "challengerId": 100,
                "memberId": 200,
                "gisu": 10,
                "part": "PLAN",
                "challengerPoints": [
                    {
                        "id": 1,
                        "pointType": "WARNING",
                        "point": 1.0,
                        "description": "지각",
                        "createdAt": "2026-02-12T06:05:45.450Z"
                    }
                ],
                "name": "홍길동",
                "nickname": "gildong",
                "email": "test@example.com",
                "schoolId": 5,
                "schoolName": "서울대학교",
                "profileImageLink": "https://example.com/image.png",
                "status": "ACTIVE"
            }
            """
            let data = json.data(using: .utf8)!

            // When
            let dto = try JSONDecoder().decode(ChallengerMemberDTO.self, from: data)

            // Then
            #expect(dto.challengerId == 100)
            #expect(dto.memberId == 200)
            #expect(dto.gisu == 10)
            #expect(dto.part == "PLAN")
            #expect(dto.challengerPoints.count == 1)
            #expect(dto.challengerPoints[0].pointType == .warning)
            #expect(dto.challengerPoints[0].createdAt == "2026-02-12T06:05:45.450Z")
            #expect(dto.status == .active)
        }

        @Test("toGenerationData_패널티_포인트만_필터링")
        func toGenerationData_패널티_포인트만_필터링() {
            // Given
            let dto = ChallengerMemberDTO(
                challengerId: 100,
                memberId: 200,
                gisu: 10,
                part: "PLAN",
                challengerPoints: [
                    ChallengerPointDTO(
                        id: 1, pointType: .bestWorkbook,
                        point: 5.0, description: "우수 워크북",
                        createdAt: "2026-01-01T00:00:00.000Z"
                    ),
                    ChallengerPointDTO(
                        id: 2, pointType: .warning,
                        point: 1.0, description: "지각",
                        createdAt: "2026-02-10T09:00:00.000Z"
                    ),
                    ChallengerPointDTO(
                        id: 3, pointType: .out,
                        point: 3.0, description: "행사 노쇼",
                        createdAt: "2026-02-11T09:00:00.000Z"
                    )
                ],
                name: "홍길동",
                nickname: "gildong",
                email: "test@example.com",
                schoolId: 5,
                schoolName: "서울대학교",
                profileImageLink: "",
                status: .active
            )

            // When
            let result = dto.toGenerationData(gisuId: 50)

            // Then - bestWorkbook은 제외, warning + out만 포함
            #expect(result.gisuId == 50)
            #expect(result.gen == 10)
            #expect(result.penaltyPoint == 4) // 1 + 3
            #expect(result.penaltyLogs.count == 2)
            #expect(result.penaltyLogs[0].reason == "지각")
            #expect(result.penaltyLogs[1].reason == "행사 노쇼")
        }

        @Test("toGenerationData_createdAt_날짜_포맷_변환")
        func toGenerationData_createdAt_날짜_포맷_변환() {
            // Given
            let dto = ChallengerMemberDTO(
                challengerId: 1,
                memberId: 1,
                gisu: 9,
                part: "WEB",
                challengerPoints: [
                    ChallengerPointDTO(
                        id: 1, pointType: .warning,
                        point: 1.0, description: "결석",
                        createdAt: "2026-03-15T14:30:00.000Z"
                    )
                ],
                name: "테스트",
                nickname: "test",
                email: "t@t.com",
                schoolId: 1,
                schoolName: "테스트대",
                profileImageLink: "",
                status: .active
            )

            // When
            let result = dto.toGenerationData(gisuId: 30)

            // Then - ISO8601 → yyyy.MM.dd
            #expect(result.penaltyLogs[0].date == "2026.03.15")
        }

        @Test("toGenerationData_패널티_없으면_빈_배열")
        func toGenerationData_패널티_없으면_빈_배열() {
            // Given
            let dto = ChallengerMemberDTO(
                challengerId: 1,
                memberId: 1,
                gisu: 11,
                part: "IOS",
                challengerPoints: [
                    ChallengerPointDTO(
                        id: 1, pointType: .bestWorkbook,
                        point: 10.0, description: "우수",
                        createdAt: "2026-01-01T00:00:00.000Z"
                    )
                ],
                name: "테스트",
                nickname: "test",
                email: "t@t.com",
                schoolId: 1,
                schoolName: "테스트대",
                profileImageLink: "",
                status: .active
            )

            // When
            let result = dto.toGenerationData(gisuId: 60)

            // Then
            #expect(result.penaltyPoint == 0)
            #expect(result.penaltyLogs.isEmpty)
        }
    }

    // MARK: - MyProfileResponseDTO

    @Suite("MyProfileResponseDTO")
    @MainActor
    struct MyProfileResponseDTOTests {

        @Test("toHomeProfileResult_SeasonTypes_변환")
        func toHomeProfileResult_SeasonTypes_변환() {
            // Given
            let dto = MyProfileResponseDTO(
                id: 1,
                name: "홍길동",
                nickname: "gildong",
                email: "test@test.com",
                schoolId: 5,
                schoolName: "서울대학교",
                profileImageLink: "",
                status: .active,
                roles: [
                    RoleDTO(
                        id: 1, challengerId: 100,
                        roleType: .challenger,
                        organizationType: .school,
                        organizationId: 5, responsiblePart: nil,
                        gisu: 9, gisuId: 50
                    ),
                    RoleDTO(
                        id: 2, challengerId: 200,
                        roleType: .challenger,
                        organizationType: .school,
                        organizationId: 5, responsiblePart: nil,
                        gisu: 10, gisuId: 60
                    )
                ],
                challengerRecords: nil
            )

            // When
            let result = dto.toHomeProfileResult()

            // Then
            #expect(result.seasonTypes.count == 2)
            if case .days(let days) = result.seasonTypes[0] {
                #expect(days == 165)
            } else {
                Issue.record("Expected .days")
            }
            if case .gens(let gens) = result.seasonTypes[1] {
                #expect(gens == [9, 10])
            } else {
                Issue.record("Expected .gens")
            }
        }

        @Test("toHomeProfileResult_ChallengerRoles_변환")
        func toHomeProfileResult_ChallengerRoles_변환() {
            // Given
            let dto = MyProfileResponseDTO(
                id: 1,
                name: "홍길동",
                nickname: "gildong",
                email: "test@test.com",
                schoolId: 5,
                schoolName: "서울대학교",
                profileImageLink: "",
                status: .active,
                roles: [
                    RoleDTO(
                        id: 1, challengerId: 100,
                        roleType: .challenger,
                        organizationType: .school,
                        organizationId: 5, responsiblePart: nil,
                        gisu: 9, gisuId: 50
                    ),
                    RoleDTO(
                        id: 2, challengerId: 200,
                        roleType: .schoolPartLeader,
                        organizationType: .school,
                        organizationId: 5, responsiblePart: "IOS",
                        gisu: 10, gisuId: 60
                    )
                ],
                challengerRecords: nil
            )

            // When
            let result = dto.toHomeProfileResult()

            // Then
            #expect(result.roles.count == 2)
            #expect(result.roles[0].challengerId == 100)
            #expect(result.roles[0].gisu == 9)
            #expect(result.roles[0].gisuId == 50)
            #expect(result.roles[1].challengerId == 200)
            #expect(result.roles[1].gisu == 10)
            #expect(result.roles[1].gisuId == 60)
        }

        @Test("highestRole_최고_권한_반환")
        func highestRole_최고_권한_반환() {
            // Given
            let dto = MyProfileResponseDTO(
                id: 1,
                name: "테스트",
                nickname: "test",
                email: "t@t.com",
                schoolId: 1,
                schoolName: "테스트대",
                profileImageLink: "",
                status: .active,
                roles: [
                    RoleDTO(
                        id: 1, challengerId: 100,
                        roleType: .challenger,
                        organizationType: .school,
                        organizationId: 1, responsiblePart: nil,
                        gisu: 9, gisuId: 50
                    ),
                    RoleDTO(
                        id: 2, challengerId: 200,
                        roleType: .schoolPartLeader,
                        organizationType: .school,
                        organizationId: 1, responsiblePart: "IOS",
                        gisu: 10, gisuId: 60
                    )
                ],
                challengerRecords: nil
            )

            // When
            let highest = dto.highestRole()

            // Then
            #expect(highest == .schoolPartLeader)
        }
    }

    // MARK: - NoticeListRequestDTO

    @Suite("NoticeListRequestDTO")
    @MainActor
    struct NoticeListRequestDTOTests {

        @Test("queryItems_필수_파라미터_포함")
        func queryItems_필수_파라미터_포함() {
            // Given
            let dto = NoticeListRequestDTO(gisuId: 50)

            // When
            let items = dto.queryItems

            // Then
            #expect(items["gisuId"] as? Int == 50)
            #expect(items["page"] as? Int == 0)
            #expect(items["size"] as? Int == 10)
            #expect(items["sort"] as? [String] == ["createdAt,DESC"])
        }

        @Test("queryItems_선택_파라미터_포함")
        func queryItems_선택_파라미터_포함() {
            // Given
            let dto = NoticeListRequestDTO(
                gisuId: 60,
                chapterId: 3,
                schoolId: 5,
                page: 1,
                size: 20
            )

            // When
            let items = dto.queryItems

            // Then
            #expect(items["gisuId"] as? Int == 60)
            #expect(items["chapterId"] as? Int == 3)
            #expect(items["schoolId"] as? Int == 5)
            #expect(items["page"] as? Int == 1)
            #expect(items["size"] as? Int == 20)
        }

        @Test("queryItems_nil_파라미터_미포함")
        func queryItems_nil_파라미터_미포함() {
            // Given
            let dto = NoticeListRequestDTO(gisuId: 50)

            // When
            let items = dto.queryItems

            // Then
            #expect(items["chapterId"] == nil)
            #expect(items["schoolId"] == nil)
            #expect(items["part"] == nil)
        }
    }

    // MARK: - PointType

    @Suite("PointType")
    @MainActor
    struct PointTypeTests {

        @Test("JSON_디코딩_각_케이스")
        func JSON_디코딩_각_케이스() throws {
            let cases: [(String, PointType)] = [
                ("\"BEST_WORKBOOK\"", .bestWorkbook),
                ("\"WARNING\"", .warning),
                ("\"OUT\"", .out)
            ]

            for (json, expected) in cases {
                let data = json.data(using: .utf8)!
                let decoded = try JSONDecoder().decode(PointType.self, from: data)
                #expect(decoded == expected)
            }
        }
    }
}
