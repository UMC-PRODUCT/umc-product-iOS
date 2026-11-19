//
//  CardLinkPriorityTests.swift
//  BusinessCardDomainTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import Testing
@testable import BusinessCardDomain

@Suite("명함 링크 우선순위 (#1679)")
struct CardLinkPriorityTests {

    @Test("중복은 앞의 것만 남기고 빠진 종류는 기본 순서대로 뒤에 붙인다")
    func normalizesPriority() {
        let normalized = CardLinkType.normalizedPriority([.blog, .github, .blog])

        #expect(normalized == [.blog, .github, .linkedIn, .instagram, .personal])
    }

    @Test("맨 위 링크는 우선순위에서 값이 있는 첫 링크다")
    func primaryLinkSkipsEmptyValues() {
        let card = makeCard(github: "  ", instagram: "https://instagram.com/umc")
            .withLinkPriority([.github, .instagram])

        #expect(card.primaryLink?.type == .instagram)
        #expect(card.primaryLink?.value == "https://instagram.com/umc")
    }

    @Test("링크가 하나도 없으면 맨 위 링크도 없다")
    func noPrimaryLinkWithoutLinks() {
        #expect(makeCard().primaryLink == nil)
    }

    @Test("우선순위만 바꾸고 나머지 값은 그대로 둔다")
    func withLinkPriorityKeepsOtherValues() {
        let card = makeCard(github: "https://github.com/umc")
        let reordered = card.withLinkPriority([.personal])

        #expect(reordered.linkPriority.first == .personal)
        #expect(reordered.withLinkPriority(CardLinkType.allCases) == card)
    }

    @Test("우선순위 조회·저장 UseCase는 저장소에 위임하고, 저장할 때 순서를 정리한다")
    func useCasesDelegate() async throws {
        let repository = MockCardLinkPriorityRepository()
        repository.fetchResult = .success([.personal])

        let fetched = try await FetchCardLinkPriorityUseCase(repository: repository).execute()
        try await SaveCardLinkPriorityUseCase(repository: repository).execute([.blog, .blog])

        #expect(fetched == [.personal])
        #expect(repository.savedPriority == [.blog, .github, .linkedIn, .instagram, .personal])
    }

    private func makeCard(github: String? = nil, instagram: String? = nil) -> MyCard {
        MyCard(
            memberId: "42", name: "정의찬", nickname: "제옹",
            part: .front(type: .ios), generation: "12", university: "한양대학교",
            email: "one@umc.dev", github: github, linkedIn: nil, blog: nil,
            instagram: instagram, avatarURL: nil
        )
    }
}
