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
/// 즉 「뒷면 줄이 시안 순서대로 값 있는 것만 나오는가」(#1679)와 「앞면·뒷면 라벨이 화면에
/// 남은 항목만 화면 순서대로 읽는가」(#1363 · #1374)를 단정한다.
@Suite("명함 면 표기")
struct CardLicenseFaceTests {

    // MARK: - 1. 뒷면 연락처·링크 줄

    @Test("뒷면 줄은 이메일 → GitHub → LinkedIn → Blog → Instagram → 개인링크 순이다")
    func backFaceContactsFollowDesignOrder() {
        let kinds = card(
            email: "one@umc.dev",
            github: "github.com/umc",
            linkedIn: "linkedin.com/in/umc",
            blog: "umc.tistory.com",
            instagram: "instagram.com/umc",
            personal: "umc.dev"
        ).backFaceContacts.map(\.kind)

        #expect(kinds == [.email, .github, .linkedIn, .blog, .instagram, .personal])
    }

    @Test("값이 없거나 공백뿐인 줄은 뺀다")
    func backFaceContactsSkipEmptyValues() {
        let contacts = card(email: "  ", github: nil, blog: "umc.tistory.com").backFaceContacts

        #expect(contacts == [CardContact(kind: .blog, value: "umc.tistory.com")])
    }

    @Test("뒷면 라벨은 화면 순서대로 값을 읽고, 줄이 없으면 빈 상태 문구를 읽는다")
    func backFaceLabelReadsContactsOrEmptyState() {
        let filled = card(email: "one@umc.dev", personal: "umc.dev").backFaceAccessibilityLabel
        let empty = card().backFaceAccessibilityLabel

        #expect(filled == "뒷면. one@umc.dev, umc.dev")
        #expect(empty == "뒷면. 등록된 연락처와 소개 링크가 없어요")
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
        personal: String? = nil
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
            avatarURL: nil
        )
    }

    private enum Constants {
        static let memberId = "7F3C1A22-9B0D-4E68-BC51-2D0A6E4F91AB"
    }
}
