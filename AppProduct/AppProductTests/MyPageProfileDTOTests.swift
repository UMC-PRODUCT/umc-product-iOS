//
//  MyPageProfileDTOTests.swift
//  AppProductTests
//
//  Created by Codex on 3/9/26.
//

import XCTest
@testable import AppProduct

final class MyPageProfileDTOTests: XCTestCase {

    func test_toProfileData_운영진_역할을_활동이력에_포함하고_ADMIN_챌린저기록은_제외한다() throws {
        let sut = try makeProfileDTO(from: """
        {
          "id": "10",
          "name": "홍길동",
          "nickname": "길동",
          "email": "test@example.com",
          "schoolId": "1",
          "schoolName": "UMC University",
          "profileImageLink": null,
          "profile": null,
          "status": "ACTIVE",
          "roles": [
            {
              "id": "101",
              "challengerId": "1001",
              "roleType": "SCHOOL_PART_LEADER",
              "organizationType": "SCHOOL",
              "organizationId": "10",
              "responsiblePart": "IOS",
              "gisu": "6",
              "gisuId": "600"
            },
            {
              "id": "102",
              "challengerId": "1002",
              "roleType": "SCHOOL_ETC_ADMIN",
              "organizationType": "SCHOOL",
              "organizationId": "10",
              "responsiblePart": null,
              "gisu": "5",
              "gisuId": "500"
            }
          ],
          "challengerRecords": [
            {
              "challengerId": "2001",
              "memberId": "10",
              "gisu": "6",
              "part": "ADMIN",
              "challengerPoints": [],
              "name": "홍길동",
              "nickname": "길동",
              "email": "test@example.com",
              "schoolId": "1",
              "schoolName": "UMC University",
              "profileImageLink": null,
              "status": "ACTIVE"
            },
            {
              "challengerId": "2002",
              "memberId": "10",
              "gisu": "5",
              "part": "IOS",
              "challengerPoints": [],
              "name": "홍길동",
              "nickname": "길동",
              "email": "test@example.com",
              "schoolId": "1",
              "schoolName": "UMC University",
              "profileImageLink": null,
              "status": "ACTIVE"
            }
          ]
        }
        """)

        let profile = sut.toProfileData()

        XCTAssertEqual(profile.activityLogs.count, 3)
        XCTAssertEqual(
            profile.activityLogs.map(\.role),
            [.schoolPartLeader, .schoolEtcAdmin, .challenger]
        )
        XCTAssertEqual(
            profile.activityLogs.map(\.part),
            [.front(type: .ios), .admin, .front(type: .ios)]
        )
        XCTAssertEqual(profile.activityLogs.map(\.generation), [6, 5, 5])
    }

    func test_toProfileData_최신_ADMIN_기록이_있어도_프로필_대표파트는_일반_챌린저기록을_우선한다() throws {
        let sut = try makeProfileDTO(from: """
        {
          "id": "10",
          "name": "홍길동",
          "nickname": "길동",
          "email": "test@example.com",
          "schoolId": "1",
          "schoolName": "UMC University",
          "profileImageLink": null,
          "profile": null,
          "status": "ACTIVE",
          "roles": [],
          "challengerRecords": [
            {
              "challengerId": "2001",
              "memberId": "10",
              "gisu": "7",
              "part": "ADMIN",
              "challengerPoints": [],
              "name": "홍길동",
              "nickname": "길동",
              "email": "test@example.com",
              "schoolId": "1",
              "schoolName": "UMC University",
              "profileImageLink": null,
              "status": "ACTIVE"
            },
            {
              "challengerId": "2002",
              "memberId": "10",
              "gisu": "6",
              "part": "ANDROID",
              "challengerPoints": [],
              "name": "홍길동",
              "nickname": "길동",
              "email": "test@example.com",
              "schoolId": "1",
              "schoolName": "UMC University",
              "profileImageLink": null,
              "status": "ACTIVE"
            }
          ]
        }
        """)

        let profile = sut.toProfileData()

        XCTAssertEqual(profile.challangerInfo.gen, 6)
        XCTAssertEqual(profile.challangerInfo.part, .front(type: .android))
        XCTAssertEqual(profile.challengeId, 2002)
    }

    private func makeProfileDTO(from json: String) throws -> MyPageProfileResponseDTO {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder().decode(MyPageProfileResponseDTO.self, from: data)
    }
}
