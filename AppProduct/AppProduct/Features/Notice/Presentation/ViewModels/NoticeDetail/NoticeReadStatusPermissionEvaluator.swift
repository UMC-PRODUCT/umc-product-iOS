//
//  NoticeReadStatusPermissionEvaluator.swift
//  AppProduct
//
//  Created by Codex on 3/11/26.
//

import Foundation

/// 공지 대상과 사용자 역할을 기준으로 수신 확인 현황 접근 가능 여부를 계산합니다.
struct NoticeReadStatusPermissionEvaluator {

    // MARK: - Role Sets

    private static let executiveRoles: Set<ManagementTeam> = [
        .superAdmin,
        .centralPresident,
        .centralVicePresident
    ]

    private static let centralOperationRoles: Set<ManagementTeam> = [
        .centralOperatingTeamMember,
        .centralEducationTeamMember
    ]

    private static let schoolAdminRoles: Set<ManagementTeam> = [
        .schoolPresident,
        .schoolVicePresident,
        .schoolPartLeader,
        .schoolEtcAdmin
    ]

    // MARK: - Function

    static func canViewReadStatus(
        roles: [ManagementTeam],
        userChapterId: Int?,
        userSchoolId: Int?,
        targetAudience: TargetAudience
    ) -> Bool {
        let roleSet = Set(roles)

        if !roleSet.isDisjoint(with: executiveRoles) {
            return true
        }

        if let targetChapterId = targetAudience.chapterId {
            guard let userChapterId, userChapterId > 0 else { return false }
            return roleSet.contains(.chapterPresident) && userChapterId == targetChapterId
        }

        if let targetSchoolId = targetAudience.schoolId {
            guard let userSchoolId, userSchoolId > 0 else { return false }
            return !roleSet.isDisjoint(with: schoolAdminRoles) && userSchoolId == targetSchoolId
        }

        guard targetAudience.generation > 0 else {
            return false
        }

        return !roleSet.isDisjoint(with: centralOperationRoles)
    }
}
