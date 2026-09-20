//
//  ProjectMemberManagementViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import CoreDomain
import Foundation
import ProjectDomain
import UMCFoundation

@Observable
@MainActor
final class ProjectMemberManagementViewModel {

    // MARK: - Property

    private(set) var members: Loadable<ProjectMembers> = .idle
    private(set) var permission: ProjectPermission?
    private(set) var isSubmitting = false
    var selectedChallengers: [ChallengerInfo] = []
    var selectedPart: UMCPartType = .pm
    var selectedMember: ProjectTeamMember?
    var selectedStatus: ProjectMemberStatus = .active
    var statusReason = ""

    private let projectId: String
    private let useCase: ProjectUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        self.projectId = projectId
        useCase = container.resolve(ProjectUseCaseProviding.self).projectUseCase
    }

    // MARK: - Computed Property

    var existingMemberIds: Set<String> {
        guard let members = members.value else { return [] }
        let groups = members.partGroups.flatMap(\.members)
        return Set(
            [members.productOwner].compactMap { $0 }.map(\.memberId)
                + members.coProductOwners.map(\.memberId)
                + groups.map(\.memberId)
        )
    }

    var canChangeStatus: Bool {
        selectedMember != nil
            && selectedStatus != .unknown
            && ProjectManagementPolicy.isValidMemberStatusReason(statusReason)
            && !isSubmitting
    }

    var canAddMember: Bool { permission?.member.canCreate.allowed == true }
    var canManageMember: Bool { permission?.member.canDelete.allowed == true }

    // MARK: - Function

    func fetch() async {
        if members.value == nil { members = .loading }
        async let permissionTask = try? useCase.fetchPermissions(projectIds: [projectId])
            .first { $0.projectId == projectId }
        do {
            members = .loaded(try await useCase.fetchMembers(projectId: projectId))
        } catch {
            members = .failed(AppError.from(error))
        }
        permission = await permissionTask
    }

    func addSelectedMembers() async throws {
        let selected = selectedChallengers.filter { !existingMemberIds.contains($0.memberId) }
        guard canAddMember, !selected.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        for challenger in selected {
            _ = try await useCase.addMember(
                projectId: projectId,
                memberId: challenger.memberId,
                part: selectedPart
            )
        }
        selectedChallengers = []
        await fetch()
    }

    func remove(_ member: ProjectTeamMember) async throws {
        guard canManageMember, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        try await useCase.removeMember(
            projectId: projectId,
            memberId: member.memberId,
            reason: nil
        )
        await fetch()
    }

    func changeStatus() async throws {
        guard let selectedMember, canManageMember, canChangeStatus else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        try await useCase.changeMemberStatus(
            projectId: projectId,
            memberId: selectedMember.memberId,
            status: selectedStatus,
            reason: statusReason.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        self.selectedMember = nil
        statusReason = ""
        await fetch()
    }
}
