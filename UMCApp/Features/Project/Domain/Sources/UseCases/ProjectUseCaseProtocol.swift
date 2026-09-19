//
//  ProjectUseCaseProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import UMCFoundation

/// 프로젝트 조회·관리·권한·통계 UseCase. 메서드 의미는 ``ProjectRepositoryProtocol`` 과 같다.
public protocol ProjectUseCaseProtocol: Sendable {

    // MARK: - Query

    func fetchProjects(query: ProjectSearchQuery) async throws -> ProjectPage<ProjectSummary>
    func fetchProject(projectId: String) async throws -> ProjectDetail
    func fetchMembers(projectId: String) async throws -> ProjectMembers
    func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers]
    func fetchManagedProjects(
        gisuId: String,
        keyword: String?,
        page: Int,
        size: Int
    ) async throws -> ProjectPage<ProjectSummary>
    func fetchDraftProject(gisuId: String) async throws -> ProjectDetail?

    // MARK: - Command

    func createDraftProject(
        gisuId: String,
        productOwnerMemberId: String?
    ) async throws -> ProjectStatusResult
    func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult
    func submitProject(projectId: String) async throws -> ProjectStatusResult
    func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws -> ProjectStatusResult
    func addMember(projectId: String, memberId: String, part: UMCPartType) async throws -> String
    func removeMember(projectId: String, memberId: String, reason: String?) async throws
    func changeMemberStatus(
        projectId: String,
        memberId: String,
        status: ProjectMemberStatus,
        reason: String
    ) async throws
    func deleteProject(projectId: String) async throws
    func publishProject(projectId: String) async throws -> ProjectStatusResult
    func updatePartQuotas(projectId: String, entries: [ProjectPartQuotaEntry]) async throws
    func abortProject(projectId: String, reason: String) async throws
    func completeProjects(projectIds: [String]) async throws

    // MARK: - Permission · Statistics

    func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission]
    func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics
    func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics
    func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics
}
