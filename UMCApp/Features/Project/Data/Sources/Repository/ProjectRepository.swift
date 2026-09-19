//
//  ProjectRepository.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork
import UMCFoundation
import ProjectDomain

public final class ProjectRepository: ProjectRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private typealias SummaryPageDTO = ProjectPageResponseDTO<ProjectSummaryResponseDTO>

    private let adapter: any ProjectNetworkRequesting
    private let decoder: JSONDecoder

    // MARK: - Init

    public convenience init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.init(networkRequesting: adapter, decoder: decoder)
    }

    /// 테스트 seam — 가짜 네트워크를 주입해 응답 매핑을 검증한다.
    init(networkRequesting: any ProjectNetworkRequesting, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = networkRequesting
        self.decoder = decoder
    }

    // MARK: - Query

    public func fetchProjects(query: ProjectSearchQuery) async throws
        -> ProjectPage<ProjectSummary> {
        let page: SummaryPageDTO = try await adapter.requestResult(
            ProjectRouter.searchProjects(query: ProjectSearchQueryDTO(query: query)),
            decoder: decoder
        )
        return page.toDomain { $0.toDomain() }
    }

    public func fetchProject(projectId: String) async throws -> ProjectDetail {
        let detail: ProjectDetailResponseDTO = try await adapter.requestResult(
            ProjectRouter.getProject(projectId: projectId),
            decoder: decoder
        )
        return detail.toDomain()
    }

    public func fetchMembers(projectId: String) async throws -> ProjectMembers {
        let members: ProjectMembersResponseDTO = try await adapter.requestResult(
            ProjectRouter.getMembers(projectId: projectId),
            decoder: decoder
        )
        return members.toDomain()
    }

    public func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers] {
        let members: [String: ProjectMembersResponseDTO] = try await adapter.requestResult(
            ProjectRouter.getMembersBatch(query: ProjectIdsQueryDTO(projectIds: projectIds)),
            decoder: decoder
        )
        return members.mapValues { $0.toDomain() }
    }

    public func fetchManagedProjects(
        gisuId: String,
        keyword: String?,
        page: Int,
        size: Int
    ) async throws -> ProjectPage<ProjectSummary> {
        let query = ProjectManagedQueryDTO(
            gisuId: gisuId,
            keyword: keyword,
            page: page,
            size: size
        )
        let result: SummaryPageDTO = try await adapter.requestResult(
            ProjectRouter.getManagedProjects(query: query),
            decoder: decoder
        )
        return result.toDomain { $0.toDomain() }
    }

    public func fetchDraftProject(gisuId: String) async throws -> ProjectDetail? {
        // 작성 중인 초안이 없으면 서버가 `result: null` 을 준다.
        let draft: ProjectDetailResponseDTO? = try await adapter.requestOptionalResult(
            ProjectRouter.getDraftProject(query: ProjectGisuQueryDTO(gisuId: gisuId)),
            decoder: decoder
        )
        return draft?.toDomain()
    }

    // MARK: - Command

    public func createDraftProject(
        gisuId: String,
        productOwnerMemberId: String?
    ) async throws -> ProjectStatusResult {
        let body = CreateDraftProjectRequestDTO(
            gisuId: try projectServerInt(gisuId, field: "gisuId"),
            productOwnerMemberId: try productOwnerMemberId.map {
                try projectServerInt($0, field: "productOwnerMemberId")
            }
        )
        return try await requestStatus(ProjectRouter.createDraftProject(body: body))
    }

    public func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult {
        try await requestStatus(
            ProjectRouter.updateProject(
                projectId: projectId,
                body: UpdateProjectRequestDTO(update: update)
            )
        )
    }

    public func submitProject(projectId: String) async throws -> ProjectStatusResult {
        try await requestStatus(ProjectRouter.submitProject(projectId: projectId))
    }

    public func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws -> ProjectStatusResult {
        let body = TransferProjectOwnershipRequestDTO(
            newOwnerMemberId: try projectServerInt(newOwnerMemberId, field: "newOwnerMemberId"),
            reason: reason
        )
        return try await requestStatus(
            ProjectRouter.transferOwnership(projectId: projectId, body: body)
        )
    }

    public func addMember(projectId: String, memberId: String, part: UMCPartType) async throws
        -> String {
        let body = AddProjectMemberRequestDTO(
            memberId: try projectServerInt(memberId, field: "memberId"),
            part: part
        )
        let projectMemberId: ProjectIdentifierResponseDTO = try await adapter.requestResult(
            ProjectRouter.addMember(projectId: projectId, body: body),
            decoder: decoder
        )
        return projectMemberId.value
    }

    public func removeMember(projectId: String, memberId: String, reason: String?) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.removeMember(
                projectId: projectId,
                memberId: memberId,
                query: ProjectReasonQueryDTO(reason: reason)
            ),
            decoder: decoder
        )
    }

    public func changeMemberStatus(
        projectId: String,
        memberId: String,
        status: ProjectMemberStatus,
        reason: String
    ) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.changeMemberStatus(
                projectId: projectId,
                memberId: memberId,
                body: ChangeProjectMemberStatusRequestDTO(status: status, reason: reason)
            ),
            decoder: decoder
        )
    }

    public func deleteProject(projectId: String) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.deleteProject(projectId: projectId),
            decoder: decoder
        )
    }

    public func publishProject(projectId: String) async throws -> ProjectStatusResult {
        try await requestStatus(ProjectRouter.publishProject(projectId: projectId))
    }

    public func updatePartQuotas(
        projectId: String,
        entries: [ProjectPartQuotaEntry]
    ) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.updatePartQuotas(
                projectId: projectId,
                body: try UpdatePartQuotasRequestDTO(entries: entries)
            ),
            decoder: decoder
        )
    }

    public func abortProject(projectId: String, reason: String) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.abortProject(
                projectId: projectId,
                body: AbortProjectRequestDTO(reason: reason)
            ),
            decoder: decoder
        )
    }

    public func completeProjects(projectIds: [String]) async throws {
        try await adapter.requestSuccess(
            ProjectRouter.completeProjects(
                body: try CompleteProjectsRequestDTO(projectIds: projectIds)
            ),
            decoder: decoder
        )
    }

    // MARK: - Permission

    public func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission] {
        // 권한 API 만 쿼리 이름이 `ids` 다.
        let query = ProjectIdsQueryDTO(parameterName: "ids", projectIds: projectIds)
        let permissions: ProjectPermissionsResponseDTO = try await adapter.requestResult(
            ProjectRouter.getPermissions(query: query),
            decoder: decoder
        )
        return permissions.toDomain()
    }

    // MARK: - Statistics

    public func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics {
        try await fetchStatistics(query: ProjectStatisticsQueryDTO(projectIds: projectIds))
    }

    public func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics {
        try await fetchStatistics(query: ProjectStatisticsQueryDTO(chapterId: chapterId))
    }

    public func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics {
        let statistics: ProjectChapterMatchingStatisticsResponseDTO =
            try await adapter.requestResult(
                ProjectRouter.getMatchingStatistics(
                    query: ProjectChapterQueryDTO(chapterId: chapterId)
                ),
                decoder: decoder
            )
        return statistics.toDomain()
    }

    // MARK: - Function

    private func fetchStatistics(query: ProjectStatisticsQueryDTO) async throws
        -> ProjectChapterStatistics {
        let statistics: ProjectChapterStatisticsResponseDTO = try await adapter.requestResult(
            ProjectRouter.getStatistics(query: query),
            decoder: decoder
        )
        return statistics.toDomain()
    }

    private func requestStatus(_ target: ProjectRouter) async throws -> ProjectStatusResult {
        let status: ProjectStatusResponseDTO = try await adapter.requestResult(
            target,
            decoder: decoder
        )
        return status.toDomain()
    }
}
