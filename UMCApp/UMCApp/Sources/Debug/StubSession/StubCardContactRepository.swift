//
//  StubCardContactRepository.swift
//  UMCApp
//
//  Created by euijjang97 on 11/19/26.
//

#if DEBUG
import BusinessCardData
import BusinessCardDomain
import CoreDomain
import MyPageDomain

/// stub 세션의 명함 링크와 공개 여부 (#1678).
///
/// 「내 정보 편집」 저장소와 내 명함 저장소가 같은 값을 본다. 그래야 시뮬레이터에서
/// 공개 여부를 바꾸고 돌아왔을 때 명함 뒷면이 함께 바뀐다. 처음 값은 픽스처 프로필의
/// 링크를 모두 공개로, 이메일도 공개로 둔 것이다.
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

/// 내 명함 저장소 stub — 앞면은 픽스처 프로필, 뒷면은 공개로 둔 이메일·링크만 싣는다.
///
/// 실물 저장소처럼 공개 여부로 비공개 항목을 뺀다. 링크 값은 「내 정보 편집」에서 고친 값을
/// 따라가도록 메모리 저장소에서 읽는다. stub 세션에는 서버 인증이 없어 실물 저장소를 쓰면
/// 명함 전체가 실패한다.
struct StubBusinessCardRepository: BusinessCardRepositoryProtocol {

    func fetchMyCard(forceRefresh: Bool) async throws -> MyCard {
        let card = try StubSessionFixtures.profile.toMyCard()
        let settings = await StubCardContactStore.shared.current().normalized

        func visible(_ type: SocialLinkType) -> String? {
            let item = settings.link(type)
            return item.isPublic && !item.value.isEmpty ? item.value : nil
        }

        return MyCard(
            memberId: card.memberId,
            name: card.name,
            nickname: card.nickname,
            part: card.part,
            generation: card.generation,
            university: card.university,
            email: settings.isEmailPublic ? card.email : nil,
            github: visible(.github),
            linkedIn: visible(.linkedin),
            blog: visible(.blog),
            instagram: visible(.instagram),
            personal: visible(.personal),
            avatarURL: card.avatarURL,
            partRaw: card.partRaw
        )
    }

    /// 매번 메모리 저장소에서 읽으므로 비울 캐시가 없다.
    func invalidateMyCardCache() async {}
}
#endif
