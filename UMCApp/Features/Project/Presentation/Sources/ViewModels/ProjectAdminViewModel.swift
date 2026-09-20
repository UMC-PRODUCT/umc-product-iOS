//
//  ProjectAdminViewModel.swift
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
final class ProjectAdminViewModel {

    // MARK: - Property

    private(set) var dashboard: Loadable<ProjectAdminDashboard> = .idle
    private(set) var matchingRounds: Loadable<[ProjectMatchingRound]> = .idle
    private(set) var matchingStatistics: Loadable<ProjectChapterMatchingStatistics> = .idle
    private(set) var commandError: AppError?
    private(set) var isSubmitting = false
    var alertPrompt: AlertPrompt?

    let role: ManagementTeam?
    let gisuId: String?
    let chapterId: String?

    private let projectUseCase: ProjectUseCaseProtocol
    private let matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol
    private static let pageSize = 100

    // MARK: - Init

    init(container: DIContainer) {
        let provider = container.resolve(ProjectUseCaseProviding.self)
        projectUseCase = provider.projectUseCase
        matchingRoundUseCase = provider.matchingRoundUseCase
        role = ProjectAdminAccessPolicy.currentRole()
        gisuId = AppStorageKey.gisuIdString()
        chapterId = UserDefaults.standard.string(forKey: AppStorageKey.chapterId)
    }

    init(
        projectUseCase: ProjectUseCaseProtocol,
        matchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol,
        role: ManagementTeam?,
        gisuId: String?,
        chapterId: String?
    ) {
        self.projectUseCase = projectUseCase
        self.matchingRoundUseCase = matchingRoundUseCase
        self.role = role
        self.gisuId = gisuId
        self.chapterId = chapterId
    }

    // MARK: - Computed Property

    var canAccess: Bool {
        ProjectAdminAccessPolicy.canEnter(role: role)
    }

    var canManageMatchingRounds: Bool {
        ProjectAdminAccessPolicy.canManageMatchingRounds(role: role)
    }

    var completableProjectIds: [String] {
        guard let dashboard = dashboard.value else { return [] }
        return dashboard.projects.compactMap { project in
            actions(for: project.id).contains(.complete) ? project.id : nil
        }
    }

    func actions(for projectId: String) -> Set<ProjectAdminAction> {
        ProjectAdminAccessPolicy.availableActions(
            role: role,
            permission: dashboard.value?.permission(for: projectId)
        )
    }

    // MARK: - Query

    func fetch() async {
        guard canAccess, let gisuId, !gisuId.isEmpty else {
            dashboard = .loaded(ProjectAdminDashboard(
                projects: [],
                permissions: [:],
                statistics: nil
            ))
            matchingRounds = .loaded([])
            return
        }

        dashboard = .loading
        do {
            let projects = try await ProjectManagedPageLoader.fetchAll(
                pageSize: Self.pageSize
            ) { page, size in
                try await self.projectUseCase.fetchManagedProjects(
                    gisuId: gisuId,
                    keyword: nil,
                    page: page,
                    size: size
                )
            }
            let projectIds = projects.map(\.id)
            let permissions = try await fetchPermissionMap(projectIds: projectIds)
            let statistics = try await fetchStatistics(
                projectIds: projectIds.filter {
                    permissions[$0]?.statistics.canRead.allowed == true
                }
            )
            dashboard = .loaded(ProjectAdminDashboard(
                projects: projects,
                permissions: permissions,
                statistics: statistics
            ))
        } catch {
            dashboard = .failed(AppError.from(error))
        }

        await fetchMatchingRoundData()
    }

    func fetchMatchingRoundData() async {
        guard canManageMatchingRounds, let chapterId, !chapterId.isEmpty else {
            matchingRounds = .loaded([])
            matchingStatistics = .idle
            return
        }

        matchingRounds = .loading
        matchingStatistics = .loading
        do {
            matchingRounds = .loaded(try await matchingRoundUseCase.fetchMatchingRounds(
                chapterId: chapterId,
                time: nil
            ))
        } catch {
            matchingRounds = .failed(AppError.from(error))
        }
        do {
            matchingStatistics = .loaded(
                try await projectUseCase.fetchMatchingStatistics(chapterId: chapterId)
            )
        } catch {
            matchingStatistics = .failed(AppError.from(error))
        }
    }

    // MARK: - Project Command

    func publish(projectId: String) async {
        guard actions(for: projectId).contains(.publish) else { return }
        await perform {
            _ = try await self.projectUseCase.publishProject(projectId: projectId)
        }
    }

    func updatePartQuotas(projectId: String, values: [UMCPartType: String]) async {
        guard actions(for: projectId).contains(.editPartQuota) else { return }
        let entries = values.compactMap { part, value -> ProjectPartQuotaEntry? in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let quota = Int(trimmed), quota > 0 else { return nil }
            return ProjectPartQuotaEntry(part: part, quota: String(quota))
        }
        guard entries.count == values.count, !entries.isEmpty else {
            commandError = .domain(
                .custom(message: "정원은 1명 이상으로 입력해 주세요.")
            )
            return
        }
        await perform {
            try await self.projectUseCase.updatePartQuotas(
                projectId: projectId,
                entries: entries.sorted { $0.part.sortOrder < $1.part.sortOrder }
            )
        }
    }

    func confirmAbort(projectId: String, reason: String) {
        guard actions(for: projectId).contains(.abort) else { return }
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            commandError = .domain(.custom(message: "중단 사유를 입력해 주세요."))
            return
        }
        alertPrompt = AlertPrompt(
            title: "프로젝트를 중단할까요?",
            message: "중단한 프로젝트는 다시 진행 상태로 되돌릴 수 없어요.",
            positiveBtnTitle: "중단",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.abort(projectId: projectId, reason: trimmed) }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    func confirmCompleteProjects() {
        let projectIds = completableProjectIds
        guard !projectIds.isEmpty else { return }
        alertPrompt = AlertPrompt(
            title: "기수 프로젝트를 완료할까요?",
            message: "완료 권한이 있는 프로젝트 \(projectIds.count)개를 "
                + "일괄 완료해요.",
            positiveBtnTitle: "완료",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.complete(projectIds: projectIds) }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    // MARK: - Matching Round Command

    func saveMatchingRound(
        matchingRoundId: String?,
        form: ProjectMatchingRoundForm
    ) async -> Bool {
        guard canManageMatchingRounds, let chapterId, form.isValid else { return false }
        let name = form.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = form.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let succeeded = await perform(refresh: false) {
            if let matchingRoundId {
                try await self.matchingRoundUseCase.updateMatchingRound(
                    matchingRoundId: matchingRoundId,
                    update: ProjectMatchingRoundUpdate(
                        name: name,
                        description: description.isEmpty ? nil : description,
                        type: form.type,
                        phase: form.phase,
                        startsAt: form.startsAt,
                        endsAt: form.endsAt,
                        decisionDeadline: form.decisionDeadline
                    )
                )
            } else {
                _ = try await self.matchingRoundUseCase.createMatchingRound(
                    ProjectMatchingRoundDraft(
                        name: name,
                        description: description.isEmpty ? nil : description,
                        type: form.type,
                        phase: form.phase,
                        chapterId: chapterId,
                        startsAt: form.startsAt,
                        endsAt: form.endsAt,
                        decisionDeadline: form.decisionDeadline
                    )
                )
            }
        }
        if succeeded { await fetchMatchingRoundData() }
        return succeeded
    }

    func confirmDeleteMatchingRound(_ round: ProjectMatchingRound) {
        guard canManageMatchingRounds else { return }
        alertPrompt = AlertPrompt(
            title: "\(round.name)을 삭제할까요?",
            message: "삭제한 매칭 차수는 복구할 수 없어요.",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.deleteMatchingRound(round.id) }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    func confirmAutoDecide(_ round: ProjectMatchingRound) {
        guard canManageMatchingRounds else { return }
        alertPrompt = AlertPrompt(
            title: "자동 선발을 실행할까요?",
            message: "\(round.name)의 미결정 지원서를 서버 기준으로 "
                + "자동 결정해요.",
            positiveBtnTitle: "실행",
            positiveBtnAction: { [weak self] in
                Task { @MainActor in await self?.autoDecide(round.id) }
            },
            negativeBtnTitle: "취소"
        )
    }

    func clearCommandError() {
        commandError = nil
    }

    // MARK: - Private Function

    private func fetchPermissionMap(projectIds: [String]) async throws
        -> [String: ProjectPermission] {
        guard !projectIds.isEmpty else { return [:] }
        let permissions = try await ProjectPermissionBatchLoader.fetchAll(
            projectIds: projectIds
        ) { projectIds in
            try await self.projectUseCase.fetchPermissions(projectIds: projectIds)
        }
        return Dictionary(uniqueKeysWithValues: permissions.map { ($0.projectId, $0) })
    }

    private func fetchStatistics(projectIds: [String]) async throws
        -> ProjectChapterStatistics? {
        guard !projectIds.isEmpty else { return nil }
        if let chapterId, !chapterId.isEmpty {
            return try await projectUseCase.fetchStatistics(chapterId: chapterId)
        }
        return try await projectUseCase.fetchStatistics(projectIds: projectIds)
    }

    private func abort(projectId: String, reason: String) async {
        await perform {
            try await self.projectUseCase.abortProject(projectId: projectId, reason: reason)
        }
    }

    private func complete(projectIds: [String]) async {
        await perform {
            try await self.projectUseCase.completeProjects(projectIds: projectIds)
        }
    }

    private func deleteMatchingRound(_ matchingRoundId: String) async {
        let succeeded = await perform(refresh: false) {
            try await self.matchingRoundUseCase.deleteMatchingRound(
                matchingRoundId: matchingRoundId
            )
        }
        if succeeded { await fetchMatchingRoundData() }
    }

    private func autoDecide(_ matchingRoundId: String) async {
        let succeeded = await perform(refresh: false) {
            try await self.matchingRoundUseCase.autoDecide(matchingRoundId: matchingRoundId)
        }
        if succeeded { await fetchMatchingRoundData() }
    }

    @discardableResult
    private func perform(
        refresh: Bool = true,
        operation: () async throws -> Void
    ) async -> Bool {
        guard !isSubmitting else { return false }
        isSubmitting = true
        commandError = nil
        defer { isSubmitting = false }
        do {
            try await operation()
            if refresh { await fetch() }
            return true
        } catch {
            commandError = AppError.from(error)
            return false
        }
    }
}
