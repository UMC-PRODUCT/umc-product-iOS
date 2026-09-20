//
//  ProjectApplicantsViewModels.swift
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
final class ProjectApplicantsViewModel {

    // MARK: - Property

    private(set) var applications: Loadable<[ProjectApplicationSummary]> = .idle
    var statusFilter: ProjectApplicationStatus?

    let projectId: String
    let canDecide: Bool
    private let applicationUseCase: ProjectApplicationUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String, canDecide: Bool) {
        self.projectId = projectId
        self.canDecide = canDecide
        self.applicationUseCase = container
            .resolve(ProjectUseCaseProviding.self)
            .applicationUseCase
    }

    init(
        projectId: String,
        canDecide: Bool = true,
        applicationUseCase: ProjectApplicationUseCaseProtocol
    ) {
        self.projectId = projectId
        self.canDecide = canDecide
        self.applicationUseCase = applicationUseCase
    }

    // MARK: - Function

    func fetch() async {
        applications = .loading
        do {
            applications = .loaded(try await applicationUseCase.fetchApplications(
                projectId: projectId,
                filter: ProjectApplicationFilter(status: statusFilter)
            ))
        } catch {
            applications = .failed(AppError.from(error))
        }
    }

    func selectStatus(_ status: ProjectApplicationStatus?) async {
        guard status != statusFilter else { return }
        statusFilter = status
        await fetch()
    }
}

struct ProjectApplicationInboxSection: Equatable {
    let projectId: String
    let applications: [ProjectApplicationSummary]
    let canDecide: Bool
}

@Observable
@MainActor
final class ProjectApplicationInboxViewModel {

    // MARK: - Property

    private(set) var sections: Loadable<[ProjectApplicationInboxSection]> = .idle
    private let projectIds: [String]
    private let decidableProjectIds: Set<String>
    private let applicationUseCase: ProjectApplicationUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectIds: [String], decidableProjectIds: [String]) {
        self.projectIds = projectIds
        self.decidableProjectIds = Set(decidableProjectIds)
        self.applicationUseCase = container
            .resolve(ProjectUseCaseProviding.self)
            .applicationUseCase
    }

    init(
        projectIds: [String],
        decidableProjectIds: [String] = [],
        applicationUseCase: ProjectApplicationUseCaseProtocol
    ) {
        self.projectIds = projectIds
        self.decidableProjectIds = Set(decidableProjectIds)
        self.applicationUseCase = applicationUseCase
    }

    // MARK: - Function

    func fetch() async {
        sections = .loading
        do {
            let grouped = try await applicationUseCase.fetchApplications(
                projectIds: projectIds,
                filter: ProjectApplicationFilter()
            )
            sections = .loaded(projectIds.compactMap { projectId in
                guard let applications = grouped[projectId], !applications.isEmpty else {
                    return nil
                }
                return ProjectApplicationInboxSection(
                    projectId: projectId,
                    applications: applications,
                    canDecide: decidableProjectIds.contains(projectId)
                )
            })
        } catch {
            sections = .failed(AppError.from(error))
        }
    }
}
