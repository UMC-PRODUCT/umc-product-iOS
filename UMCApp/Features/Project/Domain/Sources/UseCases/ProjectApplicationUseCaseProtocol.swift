//
//  ProjectApplicationUseCaseProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 지원 폼·지원서 UseCase. 메서드 의미는 ``ProjectApplicationRepositoryProtocol`` 과 같다.
public protocol ProjectApplicationUseCaseProtocol: Sendable {

    // MARK: - Application Form

    func fetchApplicationForm(projectId: String) async throws -> ProjectApplicationForm?
    func saveApplicationForm(
        projectId: String,
        title: String?,
        description: String?,
        sections: [ProjectFormSection]
    ) async throws -> ProjectApplicationForm

    // MARK: - Application Command

    func createApplication(projectId: String, matchingRoundId: String) async throws
        -> ProjectApplicationResult
    func updateAnswers(
        projectId: String,
        applicationId: String,
        answers: [ProjectAnswerInput]
    ) async throws -> ProjectApplicationResult
    func submitApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationResult
    func cancelApplication(
        projectId: String,
        applicationId: String,
        reason: String?
    ) async throws -> ProjectApplicationResult
    func decideApplication(
        projectId: String,
        applicationId: String,
        decision: ProjectApplicationDecision,
        reason: String?
    ) async throws -> ProjectApplicationResult

    // MARK: - Application Query

    func fetchMyApplications(
        gisuId: String,
        status: ProjectApplicationStatus?
    ) async throws -> [MyProjectApplication]
    func fetchApplications(
        projectIds: [String],
        filter: ProjectApplicationFilter
    ) async throws -> [String: [ProjectApplicationSummary]]
    func fetchApplications(
        projectId: String,
        filter: ProjectApplicationFilter
    ) async throws -> [ProjectApplicationSummary]
    func fetchApplication(projectId: String, applicationId: String) async throws
        -> ProjectApplicationDetail
}
