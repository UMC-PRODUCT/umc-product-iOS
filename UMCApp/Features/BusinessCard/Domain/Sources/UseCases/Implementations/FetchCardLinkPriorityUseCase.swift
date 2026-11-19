//
//  FetchCardLinkPriorityUseCase.swift
//  BusinessCardDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

public final class FetchCardLinkPriorityUseCase:
    FetchCardLinkPriorityUseCaseProtocol, @unchecked Sendable {

    // MARK: - Property

    private let repository: CardLinkPriorityRepositoryProtocol

    // MARK: - Init

    public init(repository: CardLinkPriorityRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func execute() async throws -> [CardLinkType] {
        try await repository.fetchLinkPriority()
    }
}
