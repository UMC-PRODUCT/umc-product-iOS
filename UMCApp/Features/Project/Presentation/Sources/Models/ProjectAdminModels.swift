//
//  ProjectAdminModels.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import Foundation
import ProjectDomain
import UMCFoundation

enum ProjectAdminAction: Hashable {
    case publish
    case editPartQuota
    case complete
    case abort
    case statistics
}

enum ProjectAdminAccessPolicy {
    static func canEnter(role: ManagementTeam?) -> Bool {
        role?.canAccessAdminMode == true
    }

    static func canManageMatchingRounds(role: ManagementTeam?) -> Bool {
        switch role {
        case .superAdmin, .centralPresident, .centralVicePresident, .chapterPresident:
            true
        case .centralOperatingTeamMember, .centralEducationTeamMember,
             .schoolPresident, .schoolVicePresident, .schoolPartLeader,
             .schoolEtcAdmin, .challenger, .none:
            false
        }
    }

    static func availableActions(
        role: ManagementTeam?,
        permission: ProjectPermission?
    ) -> Set<ProjectAdminAction> {
        guard canEnter(role: role), let permission, permission.exists else { return [] }

        var actions: Set<ProjectAdminAction> = []
        if permission.status.canPublish.allowed { actions.insert(.publish) }
        if permission.partQuota.canEdit.allowed { actions.insert(.editPartQuota) }
        if permission.status.canComplete.allowed { actions.insert(.complete) }
        if permission.status.canAbort.allowed { actions.insert(.abort) }
        if permission.statistics.canRead.allowed { actions.insert(.statistics) }
        return actions
    }

    static func currentRole(in defaults: UserDefaults = .standard) -> ManagementTeam? {
        let roles = (defaults.array(forKey: AppStorageKey.memberRoles) as? [String] ?? [])
            .compactMap(ManagementTeam.init(rawValue:))
        return ManagementTeam.highestPriority(in: roles)
            ?? defaults.string(forKey: AppStorageKey.memberRole)
                .flatMap(ManagementTeam.init(rawValue:))
    }
}

struct ProjectAdminDashboard: Equatable {
    let projects: [ProjectSummary]
    let permissions: [String: ProjectPermission]
    let statistics: ProjectChapterStatistics?

    func permission(for projectId: String) -> ProjectPermission? {
        permissions[projectId]
    }
}

struct ProjectMatchingRoundForm: Equatable {
    var name = ""
    var description = ""
    var type = ProjectMatchingType.planDeveloper
    var phase = ProjectMatchingPhase.first
    var startsAt = Date()
    var endsAt = Date().addingTimeInterval(3 * 24 * 60 * 60)
    var decisionDeadline = Date().addingTimeInterval(5 * 24 * 60 * 60)

    init(round: ProjectMatchingRound? = nil) {
        guard let round else { return }
        name = round.name
        description = round.description ?? ""
        type = round.type
        phase = round.phase
        startsAt = round.startsAt ?? Date()
        endsAt = round.endsAt ?? startsAt.addingTimeInterval(3 * 24 * 60 * 60)
        decisionDeadline = round.decisionDeadline
            ?? endsAt.addingTimeInterval(2 * 24 * 60 * 60)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && phase != .randomMatching
            && phase != .unknown
            && type != .unknown
            && startsAt < endsAt
            && endsAt < decisionDeadline
    }
}

@MainActor
enum ProjectManagedPageLoader {
    static func fetchAll(
        pageSize: Int,
        fetchPage: (Int, Int) async throws -> ProjectPage<ProjectSummary>
    ) async throws -> [ProjectSummary] {
        var projects: [ProjectSummary] = []
        var pageIndex = 0
        var hasNext: Bool

        repeat {
            let page = try await fetchPage(pageIndex, pageSize)
            projects.append(contentsOf: page.items)
            hasNext = page.hasNext
            pageIndex += 1
        } while hasNext

        return projects
    }
}

@MainActor
enum ProjectPermissionBatchLoader {
    private static let batchSize = 100

    static func fetchAll(
        projectIds: [String],
        fetchBatch: ([String]) async throws -> [ProjectPermission]
    ) async throws -> [ProjectPermission] {
        var permissions: [ProjectPermission] = []
        for startIndex in stride(from: 0, to: projectIds.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, projectIds.count)
            permissions += try await fetchBatch(
                Array(projectIds[startIndex..<endIndex])
            )
        }
        return permissions
    }
}
