//
//  ManagementTeamPriorityTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/9/26.
//

import XCTest
@testable import AppProduct

final class ManagementTeamPriorityTests: XCTestCase {

    func test_highestPriority_복수_역할_중_가장_높은_직급을_반환한다() {
        let roles: [ManagementTeam] = [
            .schoolPresident,
            .chapterPresident,
            .schoolPartLeader
        ]

        let resolvedRole = ManagementTeam.highestPriority(in: roles)

        XCTAssertEqual(resolvedRole, .chapterPresident)
    }

    func test_latestHighestPriorityRole_같은_기수에서는_직급_우선순위로_선택한다() {
        let roles = [
            ChallengerRole(
                challengerId: 1,
                gisu: 10,
                gisuId: 100,
                roleType: .schoolPresident,
                responsiblePart: nil,
                organizationType: .school,
                organizationId: 10
            ),
            ChallengerRole(
                challengerId: 1,
                gisu: 10,
                gisuId: 100,
                roleType: .chapterPresident,
                responsiblePart: nil,
                organizationType: .chapter,
                organizationId: 20
            ),
            ChallengerRole(
                challengerId: 1,
                gisu: 9,
                gisuId: 90,
                roleType: .centralVicePresident,
                responsiblePart: nil,
                organizationType: .central,
                organizationId: 30
            )
        ]

        let resolvedRole = roles.latestHighestPriorityRole

        XCTAssertEqual(resolvedRole?.roleType, .chapterPresident)
        XCTAssertEqual(resolvedRole?.gisu, 10)
        XCTAssertEqual(resolvedRole?.organizationType, .chapter)
    }
}
