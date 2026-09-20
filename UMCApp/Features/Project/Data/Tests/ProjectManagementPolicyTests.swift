//
//  ProjectManagementPolicyTests.swift
//  ProjectDataTests
//
//  Created by euijjang97 on 9/20/26.
//

import Testing
import ProjectDomain

@Suite("ProjectManagementPolicy")
struct ProjectManagementPolicyTests {

    @Test("삭제는 권한이 있어도 DRAFT·PENDING_REVIEW에서만 노출한다")
    func deleteUsesPermissionAndStatus() {
        #expect(ProjectManagementPolicy.canDelete(capabilityAllowed: true, status: .draft))
        #expect(ProjectManagementPolicy.canDelete(capabilityAllowed: true, status: .pendingReview))
        #expect(!ProjectManagementPolicy.canDelete(capabilityAllowed: true, status: .inProgress))
        #expect(!ProjectManagementPolicy.canDelete(
            capabilityAllowed: false,
            status: .draft
        ))
    }

    @Test("지원 폼 저장은 권한과 편집 가능한 상태가 모두 필요하다")
    func applicationFormSaveUsesCapabilityAndStatus() {
        #expect(ProjectManagementPolicy.canSaveApplicationForm(
            canCreate: true,
            canEdit: false,
            status: .draft
        ))
        #expect(ProjectManagementPolicy.canSaveApplicationForm(
            canCreate: false,
            canEdit: true,
            status: .pendingReview
        ))
        #expect(!ProjectManagementPolicy.canSaveApplicationForm(
            canCreate: true,
            canEdit: true,
            status: .inProgress
        ))
    }

    @Test("팀원 상태 변경 사유는 공백이 아니고 255자 이하여야 한다")
    func memberStatusReasonValidation() {
        #expect(!ProjectManagementPolicy.isValidMemberStatusReason("   "))
        #expect(ProjectManagementPolicy.isValidMemberStatusReason("개인 사정"))
        #expect(!ProjectManagementPolicy.isValidMemberStatusReason(
            String(repeating: "가", count: 256)
        ))
    }
}
