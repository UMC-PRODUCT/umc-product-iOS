//
//  ProjectApplicationRepository.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork
import UMCFoundation
import ProjectDomain

public final class ProjectApplicationRepository:
    ProjectApplicationRepositoryProtocol,
    @unchecked Sendable {

    // MARK: - Property

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

    // MARK: - Application Form

    public func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm? {
        // 폼을 아직 만들지 않았으면 서버가 `result: null` 을 준다.
        let form: ProjectApplicationFormResponseDTO? = try await adapter.requestOptionalResult(
            ProjectRouter.getApplicationForm(projectId: projectId),
            decoder: decoder
        )
        return form?.toDomain()
    }

    public func saveApplicationForm(
        projectId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) async throws -> ProjectApplicationForm {
        let body = try UpsertApplicationFormRequestDTO(
            title: title,
            description: description,
            sections: sections
        )
        let form: ProjectApplicationFormResponseDTO = try await adapter.requestResult(
            ProjectRouter.saveApplicationForm(projectId: projectId, body: body),
            decoder: decoder
        )
        return form.toDomain()
    }

    // MARK: - Application Command

    public func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult {
        let body = CreateProjectApplicationRequestDTO(
            matchingRoundId: try projectServerInt(matchingRoundId, field: "matchingRoundId")
        )
        return try await requestStatus(
            ProjectRouter.createApplication(projectId: projectId, body: body)
        )
    }

    public func updateAnswers(
        projectId: String,
        applicationId: String,
        answers: [ProjectAnswerInput]
    ) async throws -> ProjectApplicationResult {
        try await requestStatus(
            ProjectRouter.updateAnswers(
                projectId: projectId,
                applicationId: applicationId,
                body: try UpdateApplicationAnswersRequestDTO(answers: answers)
            )
        )
    }

    public func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult {
        try await requestStatus(
            ProjectRouter.submitApplication(projectId: projectId, applicationId: applicationId)
        )
    }

    public func cancelApplication(
        projectId: String,
        applicationId: String,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        try await requestStatus(
            ProjectRouter.cancelApplication(
                projectId: projectId,
                applicationId: applicationId,
                query: ProjectReasonQueryDTO(reason: reason)
            )
        )
    }

    public func decideApplication(
        projectId: String,
        applicationId: String,
        decision: ProjectApplicationDecision,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        try await requestStatus(
            ProjectRouter.decideApplication(
                projectId: projectId,
                applicationId: applicationId,
                body: UpdateApplicationDecisionRequestDTO(decision: decision, reason: reason)
            )
        )
    }

    // MARK: - Application Query

    public func fetchMyApplications(
        gisuId: String,
        status: ProjectApplicationStatus?
    ) async throws -> [MyProjectApplication] {
        let applications: [MyProjectApplicationResponseDTO] = try await adapter.requestResult(
            ProjectRouter.getMyApplications(
                query: ProjectMyApplicationsQueryDTO(gisuId: gisuId, status: status)
            ),
            decoder: decoder
        )
        return applications.map { $0.toDomain() }
    }

    public func fetchApplications(
        projectIds: [String],
        filter: ProjectApplicationFilter
    ) async throws -> [String: [ProjectApplicationSummary]] {
        let query = ProjectApplicationsQueryDTO(projectIds: projectIds, filter: filter)
        let applications: [String: [ProjectApplicationSummaryResponseDTO]] =
            try await adapter.requestResult(
                ProjectRouter.getApplicationsBatch(query: query),
                decoder: decoder
            )
        return applications.mapValues { $0.map { $0.toDomain() } }
    }

    public func fetchApplications(
        projectId: String,
        filter: ProjectApplicationFilter
    ) async throws -> [ProjectApplicationSummary] {
        let applications: [ProjectApplicationSummaryResponseDTO] = try await adapter.requestResult(
            ProjectRouter.getApplications(
                projectId: projectId,
                query: ProjectApplicationsQueryDTO(filter: filter)
            ),
            decoder: decoder
        )
        return applications.map { $0.toDomain() }
    }

    public func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail {
        let detail: ProjectApplicationDetailResponseDTO = try await adapter.requestResult(
            ProjectRouter.getApplication(projectId: projectId, applicationId: applicationId),
            decoder: decoder
        )
        return detail.toDomain()
    }

    // MARK: - Function

    private func requestStatus(_ target: ProjectRouter) async throws -> ProjectApplicationResult {
        let status: ProjectApplicationStatusResponseDTO = try await adapter.requestResult(
            target,
            decoder: decoder
        )
        return status.toDomain()
    }
}
