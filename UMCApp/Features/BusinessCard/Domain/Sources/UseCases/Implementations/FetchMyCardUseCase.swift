//
//  FetchMyCardUseCase.swift
//  BusinessCardDomain
//
//  Created by One on 8/16/26.
//

import Foundation

public final class FetchMyCardUseCase: FetchMyCardUseCaseProtocol, @unchecked Sendable {

    // MARK: - Property

    private let repository: BusinessCardRepositoryProtocol
    private let linkPriorityRepository: CardLinkPriorityRepositoryProtocol

    // MARK: - Init

    public init(
        repository: BusinessCardRepositoryProtocol,
        linkPriorityRepository: CardLinkPriorityRepositoryProtocol
    ) {
        self.repository = repository
        self.linkPriorityRepository = linkPriorityRepository
    }

    // MARK: - Function

    /// 뒷면 링크 우선순위를 못 읽으면 기본 순서로 그린다 — 순서 하나 때문에 명함 전체를
    /// 실패로 돌릴 이유는 없다 (#1679).
    public func execute(forceRefresh: Bool) async throws -> MyCard {
        let card = try await repository.fetchMyCard(forceRefresh: forceRefresh)
        let priority = (try? await linkPriorityRepository.fetchLinkPriority())
            ?? CardLinkType.allCases
        return card.withLinkPriority(priority)
    }
}
