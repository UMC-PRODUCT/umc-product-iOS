//
//  ProjectUseCase.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import UMCFoundation

/// 지금은 저장소를 그대로 잇는다 — 화면 이슈(#1476~)에서 필요한 조합 로직이 여기에 붙는다.
public final class ProjectUseCase: ProjectUseCaseProtocol {

    // MARK: - Property

    private let repository: ProjectRepositoryProtocol

    // MARK: - Init

    public init(repository: ProjectRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func fetchProjects(query: ProjectSearchQuery) async throws
        -> ProjectPage<ProjectSummary> {
        try await repository.fetchProjects(query: query)
    }

    public func fetchProject(projectId: String) async throws -> ProjectDetail {
        try await repository.fetchProject(projectId: projectId)
    }

    public func fetchMembers(projectId: String) async throws -> ProjectMembers {
        try await repository.fetchMembers(projectId: projectId)
    }

    public func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers] {
        try await repository.fetchMembers(projectIds: projectIds)
    }

    public func fetchManagedProjects(
        gisuId: String,
        keyword: String?,
        page: Int,
        size: Int
    ) async throws -> ProjectPage<ProjectSummary> {
        try await repository.fetchManagedProjects(
            gisuId: gisuId,
            keyword: keyword,
            page: page,
            size: size
        )
    }

    public func fetchDraftProject(gisuId: String) async throws -> ProjectDetail? {
        try await repository.fetchDraftProject(gisuId: gisuId)
    }

    public func createDraftProject(
        gisuId: String,
        productOwnerMemberId: String?
    ) async throws -> ProjectStatusResult {
        try await repository.createDraftProject(
            gisuId: gisuId,
            productOwnerMemberId: productOwnerMemberId
        )
    }

    public func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult {
        try await repository.updateProject(projectId: projectId, update: update)
    }

    public func submitProject(projectId: String) async throws -> ProjectStatusResult {
        try await repository.submitProject(projectId: projectId)
    }

    public func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws -> ProjectStatusResult {
        try await repository.transferOwnership(
            projectId: projectId,
            newOwnerMemberId: newOwnerMemberId,
            reason: reason
        )
    }

    public func addMember(projectId: String, memberId: String, part: UMCPartType) async throws
        -> String {
        try await repository.addMember(projectId: projectId, memberId: memberId, part: part)
    }

    public func removeMember(projectId: String, memberId: String, reason: String?) async throws {
        try await repository.removeMember(projectId: projectId, memberId: memberId, reason: reason)
    }

    public func changeMemberStatus(
        projectId: String,
        memberId: String,
        status: ProjectMemberStatus,
        reason: String
    ) async throws {
        try await repository.changeMemberStatus(
            projectId: projectId,
            memberId: memberId,
            status: status,
            reason: reason
        )
    }

    public func deleteProject(projectId: String) async throws {
        try await repository.deleteProject(projectId: projectId)
    }

    public func publishProject(projectId: String) async throws -> ProjectStatusResult {
        try await repository.publishProject(projectId: projectId)
    }

    public func updatePartQuotas(
        projectId: String,
        entries: [ProjectPartQuotaEntry]
    ) async throws {
        try await repository.updatePartQuotas(projectId: projectId, entries: entries)
    }

    public func abortProject(projectId: String, reason: String) async throws {
        try await repository.abortProject(projectId: projectId, reason: reason)
    }

    public func completeProjects(projectIds: [String]) async throws {
        try await repository.completeProjects(projectIds: projectIds)
    }

    public func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission] {
        try await repository.fetchPermissions(projectIds: projectIds)
    }

    public func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics {
        try await repository.fetchStatistics(projectIds: projectIds)
    }

    public func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics {
        try await repository.fetchStatistics(chapterId: chapterId)
    }

    public func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics {
        try await repository.fetchMatchingStatistics(chapterId: chapterId)
    }
}
