//
//  ProjectApplicationRepositoryProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 지원 폼·지원서 저장소 (`/api/v1/projects/.../application-form`, `.../applications`).
public protocol ProjectApplicationRepositoryProtocol: Sendable {

    // MARK: - Application Form

    /// 지원 폼 조회 (`GET /{projectId}/application-form`). 폼이 없으면 `nil`.
    func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm?

    /// 지원 폼 저장 (`PUT /{projectId}/application-form`). id 가 없는 섹션·질문·선택지는 새로 만든다.
    func saveApplicationForm(
        projectId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) async throws -> ProjectApplicationForm

    // MARK: - Application Command

    /// 지원서 생성 (`POST /{projectId}/applications`). 임시저장 상태로 만들어진다.
    func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult

    /// 답변 저장 (`PUT /{projectId}/applications/{applicationId}`).
    func updateAnswers(
        projectId: String,
        applicationId: String,
        answers: [ProjectAnswerInput]
    ) async throws -> ProjectApplicationResult

    /// 지원서 제출 (`POST .../{applicationId}/submit`).
    func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult

    /// 지원 취소 (`DELETE /{projectId}/applications/{applicationId}`).
    func cancelApplication(
        projectId: String,
        applicationId: String,
        reason: String?
    ) async throws -> ProjectApplicationResult

    /// 합격·불합격 결정 (`PATCH .../{applicationId}/decision`). `reason` 500자 이하.
    func decideApplication(
        projectId: String,
        applicationId: String,
        decision: ProjectApplicationDecision,
        reason: String?
    ) async throws -> ProjectApplicationResult

    // MARK: - Application Query

    /// 내 지원 내역 (`GET /me/applications`).
    func fetchMyApplications(
        gisuId: String,
        status: ProjectApplicationStatus?
    ) async throws -> [MyProjectApplication]

    /// 여러 프로젝트의 지원서 목록 (`GET /applications`, 최대 100개). 키는 projectId.
    func fetchApplications(
        projectIds: [String],
        filter: ProjectApplicationFilter
    ) async throws -> [String: [ProjectApplicationSummary]]

    /// 프로젝트 하나의 지원서 목록 (`GET /{projectId}/applications`).
    func fetchApplications(
        projectId: String,
        filter: ProjectApplicationFilter
    ) async throws -> [ProjectApplicationSummary]

    /// 지원서 상세 (`GET /{projectId}/applications/{applicationId}`).
    func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail
}
