//
//  FetchMyCardUseCaseTests.swift
//  BusinessCardDomainTests
//
//  Created by One on 8/16/26.
//

import Foundation
import Testing
import UMCFoundation
@testable import BusinessCardDomain

@Suite("FetchMyCardUseCase — Repository 위임")
struct FetchMyCardUseCaseTests {

    @Test("forceRefresh 인자를 그대로 위임하고 결과를 반환한다")
    func delegatesToRepository() async throws {
        let mock = MockBusinessCardRepository()
        let card = MyCard(
            memberId: "42", name: "정의찬", nickname: "제옹",
            part: .front(type: .ios), generation: "12", university: "한양대학교",
            email: nil, github: nil, linkedIn: nil, blog: nil, avatarURL: nil
        )
        mock.fetchMyCardResult = .success(card)
        let sut = FetchMyCardUseCase(
            repository: mock, linkPriorityRepository: MockCardLinkPriorityRepository()
        )

        let result = try await sut.execute(forceRefresh: true)

        #expect(result == card)
        #expect(mock.fetchMyCardCallCount == 1)
        #expect(mock.lastForceRefresh == true)
    }

    @Test("Repository 에러를 그대로 던진다")
    func propagatesError() async {
        let sut = FetchMyCardUseCase(
            repository: MockBusinessCardRepository(),
            linkPriorityRepository: MockCardLinkPriorityRepository()
        )

        await #expect(throws: MockError.self) {
            _ = try await sut.execute(forceRefresh: false)
        }
    }

    // MARK: - 링크 우선순위 (#1679)

    @Test("저장한 링크 우선순위를 내 명함에 입힌다")
    func appliesStoredLinkPriority() async throws {
        let mock = MockBusinessCardRepository()
        mock.fetchMyCardResult = .success(makeCard())
        let priority = MockCardLinkPriorityRepository()
        priority.fetchResult = .success([.blog, .github])
        let sut = FetchMyCardUseCase(repository: mock, linkPriorityRepository: priority)

        let card = try await sut.execute(forceRefresh: false)

        #expect(card.linkPriority == [.blog, .github, .linkedIn, .instagram, .personal])
        #expect(card.primaryLink?.type == .blog)
    }

    @Test("우선순위를 못 읽어도 명함은 기본 순서로 돌려준다")
    func fallsBackToDefaultPriority() async throws {
        let mock = MockBusinessCardRepository()
        mock.fetchMyCardResult = .success(makeCard())
        let priority = MockCardLinkPriorityRepository()
        priority.fetchResult = .failure(MockError.notStubbed)
        let sut = FetchMyCardUseCase(repository: mock, linkPriorityRepository: priority)

        let card = try await sut.execute(forceRefresh: false)

        #expect(card.linkPriority == CardLinkType.allCases)
        #expect(card.primaryLink?.type == .github)
    }

    private func makeCard() -> MyCard {
        MyCard(
            memberId: "42", name: "정의찬", nickname: "제옹",
            part: .front(type: .ios), generation: "12", university: "한양대학교",
            email: nil, github: "https://github.com/umc", linkedIn: nil,
            blog: "https://umc.tistory.com", avatarURL: nil
        )
    }
}
