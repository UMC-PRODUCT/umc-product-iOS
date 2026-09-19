//
//  ProjectRepositoryProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import UMCFoundation

/// 프로젝트 조회·관리·권한·통계 저장소 (`/api/v1/projects`).
///
/// 지원 폼·지원서는 ``ProjectApplicationRepositoryProtocol``,
/// 매칭 차수는 ``ProjectMatchingRoundRepositoryProtocol`` 이 맡는다.
public protocol ProjectRepositoryProtocol: Sendable {

    // MARK: - Query

    /// 프로젝트 목록 (`GET /`, 비로그인 허용).
    func fetchProjects(query: ProjectSearchQuery) async throws -> ProjectPage<ProjectSummary>

    /// 프로젝트 상세 (`GET /{projectId}`, 비로그인 허용).
    func fetchProject(projectId: String) async throws -> ProjectDetail

    /// 팀 구성 (`GET /{projectId}/members`).
    func fetchMembers(projectId: String) async throws -> ProjectMembers

    /// 여러 프로젝트의 팀 구성 (`GET /members`). 키는 projectId.
    func fetchMembers(projectIds: [String]) async throws -> [String: ProjectMembers]

    /// 내가 관리하는 프로젝트 목록 (`GET /me/managed`).
    func fetchManagedProjects(
        gisuId: String,
        keyword: String?,
        page: Int,
        size: Int
    ) async throws -> ProjectPage<ProjectSummary>

    /// 내 임시저장 프로젝트 (`GET /me/draft`). 없으면 `nil`.
    func fetchDraftProject(gisuId: String) async throws -> ProjectDetail?

    // MARK: - Command

    /// 임시저장 프로젝트 생성 (`POST /`). PO 를 비우면 요청자가 PO 가 된다.
    func createDraftProject(
        gisuId: String,
        productOwnerMemberId: String?
    ) async throws -> ProjectStatusResult

    /// 기본 정보 수정 (`PATCH /{projectId}`).
    func updateProject(projectId: String, update: ProjectInfoUpdate) async throws
        -> ProjectStatusResult

    /// 검토 요청 (`POST /{projectId}/submit`).
    func submitProject(projectId: String) async throws -> ProjectStatusResult

    /// PO 위임 (`POST /{projectId}/transfer-ownership`). `reason` 200자 이하.
    func transferOwnership(
        projectId: String,
        newOwnerMemberId: String,
        reason: String?
    ) async throws -> ProjectStatusResult

    /// 팀원 추가 (`POST /{projectId}/members`).
    /// - Returns: 서버가 돌려준 새 프로젝트 멤버 id.
    func addMember(projectId: String, memberId: String, part: UMCPartType) async throws -> String

    /// 팀원 제외 (`DELETE /{projectId}/members/{memberId}`).
    func removeMember(projectId: String, memberId: String, reason: String?) async throws

    /// 팀원 상태 변경 (`PATCH /{projectId}/members/{memberId}/status`). `reason` 필수, 255자 이하.
    func changeMemberStatus(
        projectId: String,
        memberId: String,
        status: ProjectMemberStatus,
        reason: String
    ) async throws

    /// 프로젝트 삭제 (`DELETE /{projectId}`).
    func deleteProject(projectId: String) async throws

    /// 공개 승인 (`POST /{projectId}/publish`).
    func publishProject(projectId: String) async throws -> ProjectStatusResult

    /// 파트 TO 일괄 설정 (`PUT /{projectId}/part-quotas`).
    func updatePartQuotas(projectId: String, entries: [ProjectPartQuotaEntry]) async throws

    /// 중단 (`POST /{projectId}/abort`). `reason` 필수, 255자 이하.
    func abortProject(projectId: String, reason: String) async throws

    /// 일괄 완료 (`POST /complete`).
    func completeProjects(projectIds: [String]) async throws

    // MARK: - Permission

    /// 여러 프로젝트에 대한 내 권한 (`GET /permissions`, 최대 100개).
    func fetchPermissions(projectIds: [String]) async throws -> [ProjectPermission]

    // MARK: - Statistics

    /// 지원 통계 (`GET /statistics`). 서버가 `projectIds`·`chapterId` 중 **정확히 하나**만 받는다.
    func fetchStatistics(projectIds: [String]) async throws -> ProjectChapterStatistics
    func fetchStatistics(chapterId: String) async throws -> ProjectChapterStatistics

    /// 지부 매칭 통계 (`GET /statistics/matchings`).
    func fetchMatchingStatistics(chapterId: String) async throws
        -> ProjectChapterMatchingStatistics
}
