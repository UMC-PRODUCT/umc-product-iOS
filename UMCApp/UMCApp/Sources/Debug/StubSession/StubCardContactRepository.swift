//
//  StubCardContactRepository.swift
//  UMCApp
//
//  Created by euijjang97 on 11/19/26.
//

#if DEBUG
import CoreDomain
import MyPageDomain

/// stub 세션의 명함 링크와 공개 여부 (#1678).
///
/// 처음 값은 픽스처 프로필의 링크를 모두 공개로, 이메일도 공개로 둔 것이다.
actor StubCardContactStore {
    static let shared = StubCardContactStore()

    private var settings: CardContactSettings?

    func current() -> CardContactSettings {
        if let settings { return settings }
        let profile = StubSessionFixtures.profile
        let links = profile.externalLinks
        let values: [SocialLinkType: String?] = [
            .github: links?.github,
            .linkedin: links?.linkedIn,
            .blog: links?.blog,
            .instagram: links?.instagram,
            .personal: links?.personal
        ]
        let seeded = CardContactSettings(
            isEmailPublic: true,
            links: values.mapValues { CardContactItem(value: $0 ?? "", isPublic: true) }
        )
        settings = seeded
        return seeded
    }

    func save(_ newValue: CardContactSettings) -> CardContactSettings {
        settings = newValue
        return newValue
    }
}

/// 「내 정보 편집」의 연락처·링크 저장소 stub.
struct StubCardContactSettingsRepository: CardContactSettingsRepositoryProtocol {

    func fetchCardContactSettings() async throws -> CardContactSettings {
        await StubCardContactStore.shared.current()
    }

    func updateCardContactSettings(
        _ settings: CardContactSettings
    ) async throws -> CardContactSettings {
        await StubCardContactStore.shared.save(settings.normalized)
    }
}

#endif
