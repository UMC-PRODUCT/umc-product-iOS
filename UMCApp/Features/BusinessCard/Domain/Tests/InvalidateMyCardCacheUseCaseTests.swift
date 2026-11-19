//
//  InvalidateMyCardCacheUseCaseTests.swift
//  BusinessCardDomainTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import Testing
@testable import BusinessCardDomain

@Suite("InvalidateMyCardCacheUseCase — Repository 위임")
struct InvalidateMyCardCacheUseCaseTests {

    @Test("내 명함 캐시 비우기를 Repository에 위임한다")
    func delegatesToRepository() async {
        let mock = MockBusinessCardRepository()
        let sut = InvalidateMyCardCacheUseCase(repository: mock)

        await sut.execute()

        #expect(mock.invalidateMyCardCacheCallCount == 1)
        #expect(mock.fetchMyCardCallCount == 0)
    }
}
