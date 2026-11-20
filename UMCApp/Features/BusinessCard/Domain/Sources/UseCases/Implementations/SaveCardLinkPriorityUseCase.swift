//
//  SaveCardLinkPriorityUseCase.swift
//  BusinessCardDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

public final class SaveCardLinkPriorityUseCase:
    SaveCardLinkPriorityUseCaseProtocol, @unchecked Sendable {

    // MARK: - Property

    private let repository: CardLinkPriorityRepositoryProtocol

    // MARK: - Init

    public init(repository: CardLinkPriorityRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func execute(_ priority: [CardLinkType]) async throws {
        try await repository.saveLinkPriority(CardLinkType.normalizedPriority(priority))
    }
}
