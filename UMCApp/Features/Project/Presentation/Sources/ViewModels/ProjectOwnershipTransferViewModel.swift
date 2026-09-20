//
//  ProjectOwnershipTransferViewModel.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import CoreDI
import CoreDomain
import Foundation
import ProjectDomain

@Observable
@MainActor
final class ProjectOwnershipTransferViewModel {

    // MARK: - Property

    var selectedChallengers: [ChallengerInfo] = [] {
        didSet {
            if selectedChallengers.count > 1 {
                selectedChallengers = Array(selectedChallengers.suffix(1))
            }
        }
    }
    var reason = ""
    private(set) var isSubmitting = false

    private let projectId: String
    private let useCase: ProjectUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        self.projectId = projectId
        useCase = container.resolve(ProjectUseCaseProviding.self).projectUseCase
    }

    // MARK: - Computed Property

    var selectedOwner: ChallengerInfo? { selectedChallengers.first }
    var canSubmit: Bool {
        selectedOwner?.part == .pm && reason.count <= 200 && !isSubmitting
    }

    // MARK: - Function

    func transfer() async throws {
        guard let selectedOwner, canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        _ = try await useCase.transferOwnership(
            projectId: projectId,
            newOwnerMemberId: selectedOwner.memberId,
            reason: reason.isEmpty ? nil : reason
        )
    }
}
