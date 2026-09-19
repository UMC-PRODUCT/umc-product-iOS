//
//  ProjectApplicationUseCase.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 지금은 저장소를 그대로 잇는다 — 지원·심사 화면 이슈(#1478)에서 로직이 붙는다.
public final class ProjectApplicationUseCase: ProjectApplicationUseCaseProtocol {

    // MARK: - Property

    private let repository: ProjectApplicationRepositoryProtocol

    // MARK: - Init

    public init(repository: ProjectApplicationRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm? {
        try await repository.fetchApplicationForm(projectId: projectId)
    }

    public func saveApplicationForm(
        projectId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) async throws -> ProjectApplicationForm {
        try await repository.saveApplicationForm(
            projectId: projectId,
            title: title,
            description: description,
            sections: sections
        )
    }

    public func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult {
        try await repository.createApplication(
            projectId: projectId,
            matchingRoundId: matchingRoundId
        )
    }

    public func updateAnswers(
        projectId: String,
        applicationId: String,
        answers: [ProjectAnswerInput]
    ) async throws -> ProjectApplicationResult {
        try await repository.updateAnswers(
            projectId: projectId,
            applicationId: applicationId,
            answers: answers
        )
    }

    public func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult {
        try await repository.submitApplication(projectId: projectId, applicationId: applicationId)
    }

    public func cancelApplication(
        projectId: String,
        applicationId: String,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        try await repository.cancelApplication(
            projectId: projectId,
            applicationId: applicationId,
            reason: reason
        )
    }

    public func decideApplication(
        projectId: String,
        applicationId: String,
        decision: ProjectApplicationDecision,
        reason: String?
    ) async throws -> ProjectApplicationResult {
        try await repository.decideApplication(
            projectId: projectId,
            applicationId: applicationId,
            decision: decision,
            reason: reason
        )
    }

    public func fetchMyApplications(
        gisuId: String,
        status: ProjectApplicationStatus?
    ) async throws -> [MyProjectApplication] {
        try await repository.fetchMyApplications(gisuId: gisuId, status: status)
    }

    public func fetchApplications(
        projectIds: [String],
        filter: ProjectApplicationFilter
    ) async throws -> [String: [ProjectApplicationSummary]] {
        try await repository.fetchApplications(projectIds: projectIds, filter: filter)
    }

    public func fetchApplications(
        projectId: String,
        filter: ProjectApplicationFilter
    ) async throws -> [ProjectApplicationSummary] {
        try await repository.fetchApplications(projectId: projectId, filter: filter)
    }

    public func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail {
        try await repository.fetchApplication(projectId: projectId, applicationId: applicationId)
    }
}
