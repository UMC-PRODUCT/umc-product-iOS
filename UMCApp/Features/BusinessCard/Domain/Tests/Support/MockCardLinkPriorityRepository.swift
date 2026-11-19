//
//  MockCardLinkPriorityRepository.swift
//  BusinessCardDomainTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
@testable import BusinessCardDomain

final class MockCardLinkPriorityRepository:
    CardLinkPriorityRepositoryProtocol, @unchecked Sendable {
    var fetchResult: Result<[CardLinkType], Error> = .success(CardLinkType.allCases)
    private(set) var savedPriority: [CardLinkType]?

    func fetchLinkPriority() async throws -> [CardLinkType] {
        try fetchResult.get()
    }

    func saveLinkPriority(_ priority: [CardLinkType]) async throws {
        savedPriority = priority
    }
}
