//
//  ProjectDetailViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import Foundation
import ProjectDomain
import UMCFoundation

/// 프로젝트 상세 + 팀원 구성.
///
/// 상세(`GET /{projectId}`)는 누구나 볼 수 있고, 팀원(`GET /{projectId}/members`)은
/// 권한(`GET /permissions`)의 `member.canRead` 가 허용될 때만 받는다.
@Observable
@MainActor
final class ProjectDetailViewModel {

    // MARK: - Property

    private(set) var project: Loadable<ProjectDetail> = .idle
    /// 팀원 읽기 권한이 없으면 `nil` — 섹션을 숨긴다.
    private(set) var members: Loadable<ProjectMembers>?
    /// 내 권한. 조회에 실패하면 `nil` 이고 모든 진입을 막힌 것으로 본다.
    /// 수정·팀원 관리·지원 관리 진입(#1477·#1478)이 이 값으로 노출을 가른다.
    private(set) var permission: ProjectPermission?
    private(set) var isPerformingAction = false
    private(set) var didDelete = false

    private let projectId: String
    private let useCase: ProjectUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        self.projectId = projectId
        useCase = container.resolve(ProjectUseCaseProviding.self).projectUseCase
    }

    // MARK: - Function

    func fetch() async {
        if project.value == nil {
            project = .loading
        }
        let useCase = useCase
        let projectId = projectId
        async let detailTask = useCase.fetchProject(projectId: projectId)
        // 서버는 권한이 없어도 실패 대신 false 를 준다. 실패는 권한 없음과 같게 다룬다.
        async let permissionTask = try? useCase.fetchPermissions(projectIds: [projectId])
            .first { $0.projectId == projectId }

        do {
            project = .loaded(try await detailTask)
        } catch {
            project = .failed(AppError.from(error))
        }
        permission = await permissionTask
        await fetchMembers()
    }

    func fetchMembers() async {
        guard permission?.member.canRead.allowed == true else {
            members = nil
            return
        }
        if members?.value == nil {
            members = .loading
        }
        do {
            members = .loaded(try await useCase.fetchMembers(projectId: projectId))
        } catch {
            members = .failed(AppError.from(error))
        }
    }

    func submitForReview() async throws {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        _ = try await useCase.submitProject(projectId: projectId)
        await fetch()
    }

    func deleteProject() async throws {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        try await useCase.deleteProject(projectId: projectId)
        didDelete = true
    }
}
