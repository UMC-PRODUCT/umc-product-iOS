//
//  CardLicenseFaceTests.swift
//  BusinessCardPresentationTests
//
//  Created by euijjang97 on 9/14/26.
//

import BusinessCardDomain
import Foundation
import Testing
import UMCFoundation
@testable import BusinessCardPresentation

/// 명함 면 표기 중 **눈으로 못 보는 규칙**만 본다.
///
/// 레이아웃은 프리뷰가 보여주므로 테스트하지 않는다. 조용히 틀려도 화면상으로는 멀쩡한 것,
/// 즉 「뒷면이 이메일과 우선순위 맨 위 링크 하나만 싣는가」(#1679)와 「앞면·뒷면 라벨이 화면에
/// 남은 항목만 화면 순서대로 읽는가」(#1363 · #1374)를 단정한다.
@Suite("명함 면 표기")
struct CardLicenseFaceTests {

    // MARK: - 뒷면 시리얼

    @Test("같은 회원은 언제나 같은 시리얼이다")
    func serialIsDeterministic() {
        let serial = card(memberId: Constants.memberId).licenseSerial

        #expect(serial == card(memberId: Constants.memberId).licenseSerial)
    }

    @Test("다른 회원은 다른 시리얼이다")
    func serialDiffersByMember() {
        #expect(card(memberId: "1").licenseSerial != card(memberId: "2").licenseSerial)
    }

    /// 시리얼은 `memberId` 를 **잘라 쓴 값이 아니어야** 한다 — 카드를 찍은 사진 한 장으로
    /// 남의 프로필 딥링크를 조립할 수 있게 되면 안 된다.
    @Test("시리얼에 memberId 원문이 남지 않는다")
    func serialHidesMemberId() {
        let serial = card(memberId: Constants.memberId).licenseSerial
        let hex = serial.replacingOccurrences(of: "-", with: "")

        #expect(!serial.contains(Constants.memberId))
        // 「앞 8자만 잘라 쓰기」 같은 축약이면 원본 어딘가에 그대로 들어 있다.
        #expect(!Constants.memberId.uppercased().contains(hex))
    }

    @Test("시리얼은 XXXX-XXXX 대문자 hex 다")
    func serialUsesFixedFormat() {
        let serial = card(memberId: Constants.memberId).licenseSerial
        let blocks = serial.split(separator: "-")

        #expect(blocks.count == 2)
        #expect(blocks.allSatisfy { $0.count == 4 })
        #expect(serial.allSatisfy { $0 == "-" || ($0.isHexDigit && !$0.isLowercase) })
    }

    // MARK: - 1. 뒷면 연락처·링크 줄

    @Test("뒷면에는 이메일과 링크 하나만 싣고, 기본 순서의 첫 링크는 GitHub 이다")
    func backFaceShowsEmailAndOneLink() {
        let kinds = card(
            email: "one@umc.dev",
            github: "github.com/umc",
            linkedIn: "linkedin.com/in/umc",
            blog: "umc.tistory.com",
            instagram: "instagram.com/umc",
            personal: "umc.dev"
        ).backFaceContacts.map(\.kind)

        #expect(kinds == [.email, .github])
    }

    @Test("사용자가 정한 우선순위에서 맨 위 링크를 싣는다")
    func backFaceFollowsLinkPriority() {
        let contacts = card(
            email: "one@umc.dev",
            github: "github.com/umc",
            instagram: "instagram.com/umc",
            linkPriority: [.instagram, .github]
        ).backFaceContacts

        #expect(contacts.map(\.kind) == [.email, .instagram])
        #expect(contacts.map(\.value) == ["one@umc.dev", "instagram.com/umc"])
    }

    @Test("값이 없거나 공백뿐인 항목은 빼고, 맨 위 링크가 비면 다음 순서 링크를 싣는다")
    func backFaceContactsSkipEmptyValues() {
        let contacts = card(
            email: "  ",
            linkedIn: "  ",
            blog: "umc.tistory.com",
            personal: "umc.dev",
            linkPriority: [.linkedIn, .personal, .blog]
        ).backFaceContacts

        #expect(contacts.map(\.kind) == [.personal])
        #expect(contacts.map(\.value) == ["umc.dev"])
    }

    @Test("줄을 누르면 이메일은 mailto, 스킴 없는 링크는 https 로 열고, 웹이 아닌 스킴은 열지 않는다")
    func backFaceContactsOpenMailOrWebOnly() {
        func urls(_ card: MyCard) -> [String?] {
            card.backFaceContacts.map(\.url?.absoluteString)
        }

        #expect(urls(card(email: "one@umc.dev", github: "github.com/umc"))
            == ["mailto:one@umc.dev", "https://github.com/umc"])
        #expect(urls(card(linkedIn: "HTTP://www.linkedin.com/in/umc/"))
            == ["HTTP://www.linkedin.com/in/umc/"])
        #expect(urls(card(blog: "https://")) == [nil])
        #expect(urls(card(instagram: "instagram://user?username=umc")) == [nil])
    }

    @Test("링크 줄은 스킴·www·끝 슬래시를 떼고 보이고, 이메일은 그대로 둔다")
    func backFaceLinksDropURLDecoration() {
        let github = card(email: "one@umc.dev", github: "https://github.com/umc/")
        let instagram = card(instagram: "HTTP://www.instagram.com/umc")

        #expect(github.backFaceContacts.map(\.value) == ["one@umc.dev", "github.com/umc"])
        #expect(instagram.backFaceContacts.map(\.value) == ["instagram.com/umc"])
    }

    @Test("뒷면 라벨은 화면 순서대로 값을 읽고, 줄이 없으면 빈 상태 문구를 읽는다")
    func backFaceLabelReadsContactsOrEmptyState() {
        let filled = card(email: "one@umc.dev", personal: "umc.dev").backFaceAccessibilityLabel
        let empty = card().backFaceAccessibilityLabel

        #expect(filled == "뒷면. one@umc.dev, umc.dev")
        #expect(empty == "뒷면. 등록된 연락처와 소개 링크가 없어요")
    }

    @Test("라이선스 뒷면은 시리얼·QR 다음에 공개 이메일과 우선순위 첫 링크를 읽는다")
    func licenseBackLabelReadsDisplayedContacts() {
        let filled = card(
            email: "one@umc.dev", github: "github.com/umc", personal: "umc.dev",
            linkPriority: [.personal, .github]
        )
        let empty = card()

        #expect(filled.licenseBackAccessibilityLabel(hasQR: true)
            == "뒷면. 시리얼 번호 \(filled.licenseSerial), 내 명함 QR 코드, one@umc.dev, umc.dev")
        #expect(empty.licenseBackAccessibilityLabel(hasQR: false)
            == "뒷면. 시리얼 번호 \(empty.licenseSerial), QR 코드를 만들지 못했어요")
    }

    // MARK: - 2. 앞면 접근성 라벨

    /// #1363 에서 기록 슬롯·파트 칩을 뺐다. 라벨에 기록이 남으면 화면에 없는 값을 읽는다.
    /// #1374 에서 기수가 발급 행 오른쪽으로 내려가 학교 뒤에서 읽는다.
    @Test("앞면 라벨은 이름·파트·학교·기수를 화면 순서대로 읽는다")
    func frontFaceLabelReadsVisibleItemsInScreenOrder() {
        let label = card(memberId: Constants.memberId).frontFaceAccessibilityLabel

        #expect(label == "앞면. 김유엠/유엠디, iOS 파트, 한양대학교, 12기")
    }

    /// 앞면이 그리는 영문 파트명과 VoiceOver 가 읽는 파트명이 같아야 한다 (#1374).
    @Test("앞면 라벨은 신규 파트를 화면과 같은 영문으로 읽는다")
    func frontFaceLabelReadsEnglishPart() {
        let label = card(memberId: Constants.memberId, part: .mobileProductEngineer)
            .frontFaceAccessibilityLabel

        #expect(label == "앞면. 김유엠/유엠디, Mobile Product Engineer 파트, 한양대학교, 12기")
    }

    // MARK: - Helper

    private func card(
        memberId: String = Constants.memberId,
        part: UMCPartType = .front(type: .ios),
        email: String? = nil,
        github: String? = nil,
        linkedIn: String? = nil,
        blog: String? = nil,
        instagram: String? = nil,
        personal: String? = nil,
        linkPriority: [CardLinkType] = CardLinkType.allCases
    ) -> MyCard {
        MyCard(
            memberId: memberId,
            name: "김유엠",
            nickname: "유엠디",
            part: part,
            generation: "12",
            university: "한양대학교",
            email: email,
            github: github,
            linkedIn: linkedIn,
            blog: blog,
            instagram: instagram,
            personal: personal,
            avatarURL: nil,
            linkPriority: linkPriority
        )
    }

    private enum Constants {
        static let memberId = "7F3C1A22-9B0D-4E68-BC51-2D0A6E4F91AB"
    }
}
