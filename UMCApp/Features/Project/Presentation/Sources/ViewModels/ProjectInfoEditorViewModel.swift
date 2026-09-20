//
//  ProjectInfoEditorViewModel.swift
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
final class ProjectInfoEditorViewModel {

    // MARK: - Property

    private(set) var loadState: Loadable<ProjectDetail> = .idle
    private(set) var isSaving = false
    var name = ""
    var projectDescription = ""
    var externalLink = ""
    var thumbnailData: Data?
    var logoData: Data?

    private let projectId: String
    private let useCase: ProjectUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        self.projectId = projectId
        useCase = container.resolve(ProjectUseCaseProviding.self).projectUseCase
    }

    // MARK: - Computed Property

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && name.count <= 100
            && projectDescription.count <= 200
            && externalLink.count <= 300
            && !isSaving
    }

    // MARK: - Function

    func fetch() async {
        guard loadState.value == nil else { return }
        loadState = .loading
        do {
            let project = try await useCase.fetchProject(projectId: projectId)
            name = project.name
            projectDescription = project.description ?? ""
            externalLink = project.externalLink ?? ""
            loadState = .loaded(project)
        } catch {
            loadState = .failed(AppError.from(error))
        }
    }

    func save() async throws {
        guard canSave else {
            throw AppError.validation(.invalidValue(
                field: "프로젝트 정보",
                reason: "입력 글자 수를 확인해주세요"
            ))
        }
        isSaving = true
        defer { isSaving = false }

        async let thumbnailFileId = upload(
            data: thumbnailData,
            category: .projectThumbnail
        )
        async let logoFileId = upload(data: logoData, category: .projectLogo)
        let uploaded = try await (thumbnailFileId, logoFileId)

        _ = try await useCase.updateProject(
            projectId: projectId,
            update: ProjectInfoUpdate(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: projectDescription,
                externalLink: externalLink,
                thumbnailFileId: uploaded.0,
                logoFileId: uploaded.1
            )
        )
    }

    private func upload(
        data: Data?,
        category: StorageFileCategory
    ) async throws -> String? {
        guard let data else { return nil }
        return try await useCase.uploadImage(jpegData: data, category: category)
    }
}
