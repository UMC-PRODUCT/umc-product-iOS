//
//  CardContactSettingsUseCaseTests.swift
//  MyPageDomainTests
//
//  Created by euijjang97 on 11/19/26.
//

import Testing
@testable import MyPageDomain

@Suite("명함 연락처·링크 UseCase (#1678)")
struct CardContactSettingsUseCaseTests {

    @Test("조회 UseCase는 저장소 값을 그대로 돌려준다")
    func fetchReturnsRepositoryValue() async throws {
        let stored = CardContactSettings(isEmailPublic: false)
        let repository = SpyCardContactSettingsRepository(stored: stored)

        let result = try await FetchCardContactSettingsUseCase(repository: repository).execute()

        #expect(result == stored)
    }

    @Test("저장 UseCase는 공백을 떼고 링크 5종을 채운 값을 저장소에 넘긴다")
    func updateSendsNormalizedSettings() async throws {
        let repository = SpyCardContactSettingsRepository(stored: CardContactSettings())
        let input = CardContactSettings(
            links: [.github: CardContactItem(value: " https://github.com/umc ", isPublic: true)]
        )

        _ = try await UpdateCardContactSettingsUseCase(repository: repository).execute(input)

        let received = await repository.received
        #expect(received == input.normalized)
        #expect(received?.links.count == SocialLinkType.allCases.count)
    }
}

private actor SpyCardContactSettingsRepository: CardContactSettingsRepositoryProtocol {
    private let stored: CardContactSettings
    private(set) var received: CardContactSettings?

    init(stored: CardContactSettings) {
        self.stored = stored
    }

    func fetchCardContactSettings() async throws -> CardContactSettings {
        stored
    }

    func updateCardContactSettings(
        _ settings: CardContactSettings
    ) async throws -> CardContactSettings {
        received = settings
        return settings
    }
}
