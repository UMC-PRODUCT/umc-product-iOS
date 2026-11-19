//
//  CardContactSettingsTests.swift
//  MyPageDomainTests
//
//  Created by euijjang97 on 11/19/26.
//

import Testing
@testable import MyPageDomain

@Suite("CardContactSettings — 정규화·형식 검사 (#1678)")
struct CardContactSettingsTests {

    // MARK: - normalized

    @Test("정규화하면 값 앞뒤 공백을 떼고 링크 5종을 모두 채운다")
    func normalizedTrimsAndFillsAllLinks() {
        let settings = CardContactSettings(
            isEmailPublic: false,
            links: [.github: CardContactItem(value: " https://github.com/umc ", isPublic: true)]
        )

        let normalized = settings.normalized

        #expect(normalized.isEmailPublic == false)
        #expect(normalized.link(.github).value == "https://github.com/umc")
        #expect(normalized.links.count == SocialLinkType.allCases.count)
        #expect(normalized.link(.blog) == .empty)
    }

    @Test("공백만 다르고 빠진 링크를 빈 값으로 채운 것뿐이면 정규화 결과가 같다")
    func normalizedIgnoresWhitespaceAndMissingLinks() {
        let saved = CardContactSettings(
            links: Dictionary(
                uniqueKeysWithValues: SocialLinkType.allCases.map { ($0, CardContactItem.empty) }
            )
        )
        let edited = CardContactSettings(
            links: [.github: CardContactItem(value: "   ", isPublic: true)]
        )

        #expect(edited.normalized == saved.normalized)
    }

    // MARK: - firstInvalidLink

    @Test("바뀐 링크가 http(s)와 점이 든 호스트가 아니면 그 링크를 돌려준다")
    func invalidChangedLinks() {
        let saved = CardContactSettings()
        let cases: [(String, Bool)] = [
            ("github.com/umc", false),
            ("ftp://github.com/umc", false),
            ("https://localhost", false),
            ("https://github.com/umc", true),
            ("HTTP://www.github.com/umc", true)
        ]

        for (value, isValid) in cases {
            let edited = CardContactSettings(
                links: [.github: CardContactItem(value: value, isPublic: true)]
            )
            let expected: SocialLinkType? = isValid ? nil : .github
            #expect(edited.firstInvalidLink(comparedTo: saved) == expected, "\(value)")
        }
    }

    /// 예전 링크 API로 스킴 없이 저장한 값이 남아 있어도 다른 항목 저장까지 막지 않는다.
    @Test("손대지 않은 값과 비운 값은 형식을 따지지 않는다")
    func unchangedOrEmptyValuesPass() {
        let saved = CardContactSettings(
            links: [
                .github: CardContactItem(value: "github.com/legacy", isPublic: true),
                .blog: CardContactItem(value: "https://blog.umc.dev", isPublic: true)
            ]
        )
        var edited = saved
        edited.links[.github]?.isPublic = false
        edited.links[.blog]?.value = ""

        #expect(edited.firstInvalidLink(comparedTo: saved) == nil)
    }
}
