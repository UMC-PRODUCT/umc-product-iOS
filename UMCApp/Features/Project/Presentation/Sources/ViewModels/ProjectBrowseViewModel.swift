//
//  ProjectBrowseViewModel.swift
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
final class ProjectBrowseViewModel {

    // MARK: - Property

    private(set) var projects: Loadable<[ProjectSummary]> = .idle
    private(set) var isLoadingNextPage = false

    private let projectUseCase: ProjectUseCaseProtocol
    private let gisuId: String?
    private var nextPage = 0
    private var hasNext = false
    private static let pageSize = 20

    // MARK: - Init

    init(container: DIContainer) {
        self.projectUseCase = container.resolve(ProjectUseCaseProviding.self).projectUseCase
        self.gisuId = AppStorageKey.gisuIdString()
    }

    init(projectUseCase: ProjectUseCaseProtocol, gisuId: String?) {
        self.projectUseCase = projectUseCase
        self.gisuId = gisuId
    }

    // MARK: - Function

    func fetch() async {
        guard let gisuId else {
            projects = .loaded([])
            return
        }
        projects = .loading
        do {
            let page = try await projectUseCase.fetchProjects(
                query: Self.query(gisuId: gisuId, page: 0)
            )
            projects = .loaded(page.items)
            nextPage = 1
            hasNext = page.hasNext
        } catch {
            projects = .failed(AppError.from(error))
        }
    }

    func loadNextPage() async throws {
        guard let gisuId, hasNext, !isLoadingNextPage, var current = projects.value else {
            return
        }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }
        let page = try await projectUseCase.fetchProjects(
            query: Self.query(gisuId: gisuId, page: nextPage)
        )
        current.append(contentsOf: page.items)
        projects = .loaded(current)
        nextPage += 1
        hasNext = page.hasNext
    }

    private static func query(gisuId: String, page: Int) -> ProjectSearchQuery {
        ProjectSearchQuery(
            gisuId: gisuId,
            statuses: [.inProgress],
            page: page,
            size: pageSize
        )
    }
}
