//
//  ProjectAdminAccessPolicyTests.swift
//  ProjectPresentationTests
//
//  Created by euijjang97 on 9/20/26.
//

import ProjectDomain
import Testing
import UMCFoundation
@testable import ProjectPresentation

@Suite("ProjectAdminAccessPolicy")
struct ProjectAdminAccessPolicyTests {

    @Test("챌린저는 capability가 허용돼도 운영 화면에 진입할 수 없다")
    func challengerCannotAccessAdminEntry() {
        let permission = makePermission(allowsOperations: true)

        #expect(ProjectAdminAccessPolicy.canEnter(role: .challenger) == false)
        #expect(
            ProjectAdminAccessPolicy.availableActions(
                role: .challenger,
                permission: permission
            ).isEmpty
        )
    }

    @Test("운영진에게는 서버 capability가 허용한 작업만 노출한다")
    func operatorSeesOnlyAllowedCapabilities() {
        let permission = makePermission(
            canPublish: true,
            canEditQuota: false,
            canComplete: true,
            canAbort: false,
            canReadStatistics: true
        )

        let actions = ProjectAdminAccessPolicy.availableActions(
            role: .chapterPresident,
            permission: permission
        )

        #expect(actions == [.publish, .complete, .statistics])
    }

    @Test("권한 응답이 없으면 운영진도 프로젝트 작업을 열지 않는다")
    func missingPermissionDeniesProjectActions() {
        #expect(
            ProjectAdminAccessPolicy.availableActions(
                role: .centralPresident,
                permission: nil
            ).isEmpty
        )
    }

    @Test(
        "매칭 차수 관리는 총괄단과 지부장만 가능하다",
        arguments: [
            ManagementTeam.superAdmin,
            .centralPresident,
            .centralVicePresident,
            .chapterPresident,
        ]
    )
    func matchingRoundManagementAllowsOnlyLeadership(role: ManagementTeam) {
        #expect(ProjectAdminAccessPolicy.canManageMatchingRounds(role: role))
    }

    @Test(
        "중앙 운영국과 교육국은 매칭 차수를 관리할 수 없다",
        arguments: [
            ManagementTeam.centralOperatingTeamMember,
            .centralEducationTeamMember,
        ]
    )
    func matchingRoundManagementDeniesCentralMembers(role: ManagementTeam) {
        #expect(ProjectAdminAccessPolicy.canManageMatchingRounds(role: role) == false)
    }
}

private func makePermission(
    allowsOperations: Bool = false,
    canPublish: Bool = false,
    canEditQuota: Bool = false,
    canComplete: Bool = false,
    canAbort: Bool = false,
    canReadStatistics: Bool = false
) -> ProjectPermission {
    let denied = ProjectCapability.denied
    let publish = ProjectCapability(allowed: allowsOperations || canPublish)
    let quota = ProjectCapability(allowed: allowsOperations || canEditQuota)
    let complete = ProjectCapability(allowed: allowsOperations || canComplete)
    let abort = ProjectCapability(allowed: allowsOperations || canAbort)
    let statistics = ProjectCapability(allowed: allowsOperations || canReadStatistics)
    return ProjectPermission(
        projectId: "101",
        exists: true,
        canEditInfo: denied,
        canTransferOwnership: denied,
        canDelete: denied,
        applicationForm: .init(
            canRead: denied,
            canCreate: denied,
            canEdit: denied,
            canPublish: denied,
            canDelete: denied
        ),
        partQuota: .init(canEdit: quota),
        status: .init(
            canRequestReview: denied,
            canPublish: publish,
            canComplete: complete,
            canAbort: abort
        ),
        application: .init(
            canCreate: denied,
            canReadList: denied,
            canDecide: denied
        ),
        member: .init(canRead: denied, canCreate: denied, canDelete: denied),
        statistics: .init(canRead: statistics)
    )
}
