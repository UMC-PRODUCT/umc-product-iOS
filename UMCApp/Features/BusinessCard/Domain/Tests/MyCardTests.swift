//
//  MyCardTests.swift
//  BusinessCardDomainTests
//
//  Created by One on 8/16/26.
//

import Foundation
import Testing
import UMCFoundation
@testable import BusinessCardDomain

@Suite("MyCard — 파생 프로퍼티")
struct MyCardTests {

    /// 명함_l·_m·_s 세 카드가 이 한 규칙을 공유한다 (#1236). 잘림은 뷰가 처리하므로
    /// 여기서는 길이를 자르지 않고 원문을 그대로 잇는지만 본다.
    ///
    /// 마지막 줄은 이름이 빈 퇴화 상태의 **현재 동작**을 적어 둔 것이다 — 서버가 이름을
    /// 안 주는 카드는 ``MyCard/validate()`` 가 아니라 여기서 `/닉네임` 으로 새 나간다.
    private static let nameCases: [(name: String, nickname: String, expected: String)] = [
        (name: "김민", nickname: "민", expected: "김민/민"),
        (name: "남궁수하늘보라매", nickname: "구름", expected: "남궁수하늘보라매/구름"),
        (name: "Christopher Nolan", nickname: "Chris", expected: "Christopher Nolan/Chris"),
        (name: "박서준", nickname: "", expected: "박서준"),
        (name: "박서준", nickname: "  ", expected: "박서준"),
        (name: "김민", nickname: " 민 ", expected: "김민/민"),
        (name: "", nickname: "민", expected: "/민"),
    ]

    @Test("qrPayload는 cardLink urlString과 항상 같다 (MP-F02·F04 동일 페이로드)")
    func qrPayloadEqualsCardLink() {
        let card = MyCard(
            memberId: "42", name: "정의찬", nickname: "제옹",
            part: .front(type: .ios), generation: "12", university: "한양대학교",
            email: nil, github: nil, linkedIn: nil, blog: nil, avatarURL: nil
        )

        #expect(card.qrPayload == CardLink(memberId: "42").urlString)
        #expect(card.qrPayload == card.cardLink.urlString)
    }

    @Test("닉네임이 있으면 `이름/닉네임`, 공백뿐이면 이름만 싣는다", arguments: nameCases)
    func nameWithNicknameFollowsDesignDummy(
        nameCase: (name: String, nickname: String, expected: String)
    ) {
        let card = MyCard(
            memberId: "42", name: nameCase.name, nickname: nameCase.nickname,
            part: .front(type: .ios), generation: "12", university: "한양대학교",
            email: nil, github: nil, linkedIn: nil, blog: nil, avatarURL: nil
        )

        #expect(card.nameWithNickname == nameCase.expected)
    }

    /// 명함만 신규 두 파트를 영문으로 쓴다 (#1374). `UMCPartType.name` 은 다른 피처가
    /// 한글로 쓰므로 그대로여야 한다 — 두 값이 갈리는 것 자체가 의도다.
    @Test(
        "명함 파트명은 신규 두 파트만 영문이고 나머지는 UMCPartType.name 그대로다",
        arguments: [
            (UMCPartType.mobileProductEngineer, "Mobile Product Engineer"),
            (UMCPartType.webProductEngineer, "Web Product Engineer"),
            (UMCPartType.front(type: .ios), "iOS"),
            (UMCPartType.pm, "PM"),
        ]
    )
    func partDisplayNameUsesEnglishOnCard(part: UMCPartType, expected: String) {
        let card = MyCard(
            memberId: "42", name: "정의찬", nickname: "제옹",
            part: part, generation: "12", university: "한양대학교",
            email: nil, github: nil, linkedIn: nil, blog: nil, avatarURL: nil
        )

        #expect(card.partDisplayName == expected)
    }

    @Test("신규 파트의 UMCPartType.name 은 한글 표시명을 유지한다")
    func partTypeNameStaysKorean() {
        #expect(UMCPartType.mobileProductEngineer.name == "모바일 프로덕트 엔지니어")
        #expect(UMCPartType.webProductEngineer.name == "웹 프로덕트 엔지니어")
    }
}
