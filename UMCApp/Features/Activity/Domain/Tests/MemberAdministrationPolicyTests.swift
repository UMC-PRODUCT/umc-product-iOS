// Created by euijjang97 on 11/1/26.
import Testing
import CoreDomain
import UMCFoundation
@testable import ActivityDomain

struct MemberAdministrationPolicyTests {
    @Test func historicalPointsUseServerSignRatherThanCurrentTypeDefault() {
        #expect(!OperatorMemberPenaltyHistory.isReward(type: .bestWorkbook, signedPoint: -2))
        #expect(OperatorMemberPenaltyHistory.isReward(type: .studyLate, signedPoint: 2))
        #expect(OperatorMemberPenaltyHistory.isReward(type: .warning, signedPoint: 1))
        #expect(!OperatorMemberPenaltyHistory.isReward(type: .out, signedPoint: -1))
    }
    private func authority(_ role: ManagementTeam, gisu: String = "10",
                           school: String? = "20", type: OrganizationType = .school)
        -> MemberAdministrationAuthority {
        .init(roles: [.init(gisu: "10", gisuId: gisu, roleType: role,
                           organizationType: type, organizationId: school)])
    }

    @Test func schoolCoreRequiresMatchingSchoolAndGeneration() {
        let policy = authority(.schoolVicePresident)
        #expect(policy.canManagePoints(gisuId: "10", schoolId: "20"))
        #expect(!policy.canManagePoints(gisuId: "11", schoolId: "20"))
        #expect(!policy.canManagePoints(gisuId: "10", schoolId: "21"))
        #expect(!authority(.schoolPartLeader).canManagePoints(gisuId: "10", schoolId: "20"))
    }

    @Test func centralScopeAndDeletionRequireTargetGeneration() {
        let education = authority(.centralEducationTeamMember, type: .central)
        #expect(education.canManagePoints(gisuId: "10", schoolId: "99"))
        #expect(!education.canDeletePoints(gisuId: "10"))
        let president = authority(.centralPresident, type: .central)
        #expect(president.canDeletePoints(gisuId: "10"))
        #expect(!president.canDeletePoints(gisuId: "11"))
        #expect(!authority(.centralPresident).canDeletePoints(gisuId: "10"))
    }

    @Test func systemAdministratorDoesNotNeedMembership() {
        let policy = MemberAdministrationAuthority(roles: [], isSuperAdmin: true)
        #expect(policy.canManagePoints(gisuId: "10", schoolId: "20"))
        #expect(policy.canDeletePoints(gisuId: "10"))
        #expect(policy.canSearchAllSchools(gisuId: "10"))
    }

    @Test func generationTenExcludesLegacyWorkbookOnly() {
        #expect(!MemberPointValidation.availableTypes(generation: "10").contains(.bestWorkbook))
        #expect(MemberPointValidation.availableTypes(generation: "9").contains(.bestWorkbook))
        #expect(MemberPointValidation.availableTypes(generation: "10").contains(.schoolCoreMeetingAbsent))
    }

    @Test func descriptionAndValueValidationEnforceServerBoundaries() throws {
        try MemberPointValidation.validate(type: .custom, value: Int(Int32.min), description: "사유")
        try MemberPointValidation.validate(type: .custom, value: Int(Int32.max), description: "사유")
        #expect(throws: (any Error).self) {
            try MemberPointValidation.validate(type: .custom, value: Int(Int32.max) + 1, description: "사유")
        }
        #expect(throws: (any Error).self) {
            try MemberPointValidation.validate(type: .custom, value: Int(Int32.min) - 1, description: "사유")
        }
        #expect(throws: (any Error).self) {
            try MemberPointValidation.validate(type: .custom, value: 0, description: "사유")
        }
        #expect(throws: (any Error).self) {
            try MemberPointValidation.validate(type: .studyLate, value: -3, description: "사유")
        }
        #expect(throws: (any Error).self) {
            try MemberPointValidation.description(" \n ")
        }
        #expect(throws: (any Error).self) {
            try MemberPointValidation.description(String(repeating: "가", count: 201))
        }
        #expect(try MemberPointValidation.description(" 사유 ") == "사유")
        try MemberPointValidation.validate(type: .custom, value: -2,
                                           description: String(repeating: "가", count: 200))
    }
}
