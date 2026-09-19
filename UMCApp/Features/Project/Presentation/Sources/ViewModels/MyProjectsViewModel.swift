//
//  MyProjectsViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import CoreDomain
import Foundation
import ProjectDomain
import UMCFoundation

/// 「내 프로젝트」 — 선택한 기수의 관리 프로젝트(+초안)와 내 지원 내역.
///
/// 두 영역은 따로 실패한다. 지원 내역의 상태 필터를 바꾸면 지원 내역만 다시 받는다.
@Observable
@MainActor
final class MyProjectsViewModel {

    // MARK: - Property

    private(set) var managed: Loadable<ManagedProjects> = .idle
    private(set) var applications: Loadable<[MyProjectApplication]> = .idle
    /// 기수 선택 메뉴 항목(최신 기수가 위). 비어 있으면 메뉴를 숨긴다.
    private(set) var generations: [ProjectGeneration] = []
    private(set) var selectedGisuId: String?
    private(set) var applicationStatus: ProjectApplicationStatus?
    private(set) var isLoadingNextPage = false

    private let projectUseCase: ProjectUseCaseProtocol
    private let applicationUseCase: ProjectApplicationUseCaseProtocol

    private static let pageSize = 20

    // MARK: - Init

    init(container: DIContainer) {
        let provider = container.resolve(ProjectUseCaseProviding.self)
        projectUseCase = provider.projectUseCase
        applicationUseCase = provider.applicationUseCase

        let pairs = (try? container.resolve(ChallengerGenRepositoryProtocol.self)
            .fetchGenGisuIdPairs()) ?? []
        // gisuId 는 서버 전달용 값이라 화면에 기수처럼 내보내지 않는다 — 매핑된 것만 메뉴에 둔다.
        generations = pairs
            .filter { !$0.gisuId.isEmpty && $0.gisuId != "0" }
            .map { ProjectGeneration(gen: $0.gen, gisuId: $0.gisuId) }
            .reversed()
        let currentGisuId = AppStorageKey.gisuIdString().flatMap { $0 == "0" ? nil : $0 }
        selectedGisuId = currentGisuId ?? generations.first?.gisuId
    }

    // MARK: - Computed Property

    var selectedGeneration: String? {
        generations.first { $0.gisuId == selectedGisuId }?.gen
    }

    // MARK: - Function

    func fetch() async {
        async let managedTask: Void = fetchManaged()
        async let applicationsTask: Void = fetchApplications()
        _ = await (managedTask, applicationsTask)
    }

    func selectGisu(_ gisuId: String) async {
        guard gisuId != selectedGisuId else { return }
        selectedGisuId = gisuId
        managed = .idle
        applications = .idle
        await fetch()
    }

    func selectApplicationStatus(_ status: ProjectApplicationStatus?) async {
        guard status != applicationStatus else { return }
        applicationStatus = status
        applications = .idle
        await fetchApplications()
    }

    /// 마지막 행이 보일 때 다음 페이지를 붙인다.
    func loadNextPage() async throws {
        guard let gisuId = selectedGisuId,
              var current = managed.value, current.hasNext, !isLoadingNextPage
        else { return }
        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        let page = try await projectUseCase.fetchManagedProjects(
            gisuId: gisuId, keyword: nil, page: current.nextPage, size: Self.pageSize
        )
        let counts = await memberCounts(projectIds: page.items.map(\.id))
        current.projects += page.items
        current.memberCounts.merge(counts) { _, new in new }
        current.nextPage += 1
        current.hasNext = page.hasNext
        managed = .loaded(current)
    }

    func fetchManaged() async {
        guard let gisuId = selectedGisuId else {
            managed = .loaded(ManagedProjects())
            return
        }
        if managed.value == nil {
            managed = .loading
        }
        let useCase = projectUseCase
        async let draftTask = useCase.fetchDraftProject(gisuId: gisuId)
        async let pageTask = useCase.fetchManagedProjects(
            gisuId: gisuId, keyword: nil, page: 0, size: Self.pageSize
        )
        do {
            let (draft, page) = try await (draftTask, pageTask)
            let counts = await memberCounts(projectIds: page.items.map(\.id))
            managed = .loaded(ManagedProjects(
                draft: draft,
                projects: page.items,
                memberCounts: counts,
                nextPage: 1,
                hasNext: page.hasNext
            ))
        } catch {
            managed = .failed(AppError.from(error))
        }
    }

    func fetchApplications() async {
        guard let gisuId = selectedGisuId else {
            applications = .loaded([])
            return
        }
        if applications.value == nil {
            applications = .loading
        }
        do {
            applications = .loaded(try await applicationUseCase.fetchMyApplications(
                gisuId: gisuId, status: applicationStatus
            ))
        } catch {
            applications = .failed(AppError.from(error))
        }
    }

    /// 인원 수는 보조 정보라 실패하면 비워 둔다. 서버는 읽기 권한 없는 프로젝트를 조용히 뺀다.
    private func memberCounts(projectIds: [String]) async -> [String: Int] {
        guard !projectIds.isEmpty,
              let members = try? await projectUseCase.fetchMembers(projectIds: projectIds)
        else { return [:] }
        return members.mapValues(\.headCount)
    }
}

// MARK: - ManagedProjects

/// 관리 프로젝트 영역 — 초안은 `/me/managed` 에 포함되지 않아 따로 받는다.
struct ManagedProjects: Equatable {
    var draft: ProjectDetail?
    var projects: [ProjectSummary] = []
    /// projectId → 팀 인원 (`GET /members` 일괄 조회).
    var memberCounts: [String: Int] = [:]
    /// 다음에 요청할 0-based 페이지.
    var nextPage = 0
    var hasNext = false

    var isEmpty: Bool { draft == nil && projects.isEmpty }
}

// MARK: - ProjectGeneration

struct ProjectGeneration: Identifiable, Equatable {
    let gen: String
    let gisuId: String

    var id: String { gisuId }
}
