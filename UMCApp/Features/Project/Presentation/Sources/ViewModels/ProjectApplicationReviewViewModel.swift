//
//  ProjectApplicationReviewViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import Foundation
import ProjectDomain
import UMCFoundation

@Observable
@MainActor
final class ProjectApplicationReviewViewModel {

    // MARK: - Property

    private(set) var application: Loadable<ProjectApplicationDetail> = .idle
    private(set) var isDeciding = false
    let canDecide: Bool

    private let projectId: String
    private let applicationId: String
    private let applicationUseCase: ProjectApplicationUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String, applicationId: String, canDecide: Bool) {
        self.projectId = projectId
        self.applicationId = applicationId
        self.canDecide = canDecide
        self.applicationUseCase = container
            .resolve(ProjectUseCaseProviding.self)
            .applicationUseCase
    }

    init(
        projectId: String,
        applicationId: String,
        canDecide: Bool,
        applicationUseCase: ProjectApplicationUseCaseProtocol
    ) {
        self.projectId = projectId
        self.applicationId = applicationId
        self.canDecide = canDecide
        self.applicationUseCase = applicationUseCase
    }

    // MARK: - Function

    func fetch() async {
        application = .loading
        do {
            application = .loaded(try await applicationUseCase.fetchApplication(
                projectId: projectId,
                applicationId: applicationId
            ))
        } catch {
            application = .failed(AppError.from(error))
        }
    }

    func decide(_ decision: ProjectApplicationDecision, reason: String?) async throws {
        guard canDecide, !isDeciding, var detail = application.value else { return }
        isDeciding = true
        defer { isDeciding = false }
        let result = try await applicationUseCase.decideApplication(
            projectId: projectId,
            applicationId: applicationId,
            decision: decision,
            reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
        detail = ProjectApplicationDetail(
            applicationId: detail.applicationId,
            applicant: detail.applicant,
            matchingRound: detail.matchingRound,
            status: result.status,
            submittedAt: detail.submittedAt,
            statusChangedAt: Date(),
            formResponse: detail.formResponse
        )
        application = .loaded(detail)
    }
}
