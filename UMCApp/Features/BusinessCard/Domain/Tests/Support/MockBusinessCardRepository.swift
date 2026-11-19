//
//  MockBusinessCardRepository.swift
//  BusinessCardDomainTests
//
//  Created by One on 8/16/26.
//

import Foundation
import UMCFoundation
@testable import BusinessCardDomain

enum MockError: Error { case notStubbed }

final class MockBusinessCardRepository: BusinessCardRepositoryProtocol, @unchecked Sendable {
    var fetchMyCardResult: Result<MyCard, Error> = .failure(MockError.notStubbed)
    private(set) var fetchMyCardCallCount = 0
    private(set) var lastForceRefresh: Bool?
    private(set) var invalidateMyCardCacheCallCount = 0

    func fetchMyCard(forceRefresh: Bool) async throws -> MyCard {
        fetchMyCardCallCount += 1
        lastForceRefresh = forceRefresh
        return try fetchMyCardResult.get()
    }

    func invalidateMyCardCache() async {
        invalidateMyCardCacheCallCount += 1
    }
}
