//
//  ProjectManagementPolicy.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/20/26.
//

import Foundation

/// PM 관리 화면의 권한·상태 노출 규칙.
public enum ProjectManagementPolicy {

    public static func canDelete(
        capabilityAllowed: Bool,
        status: ProjectStatus?
    ) -> Bool {
        capabilityAllowed && (status == .draft || status == .pendingReview)
    }

    public static func canSaveApplicationForm(
        canCreate: Bool,
        canEdit: Bool,
        status: ProjectStatus?
    ) -> Bool {
        (canCreate || canEdit) && (status == .draft || status == .pendingReview)
    }

    public static func isValidMemberStatusReason(_ reason: String) -> Bool {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 255
    }
}
