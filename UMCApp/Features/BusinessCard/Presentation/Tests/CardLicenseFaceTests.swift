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

/// 라이선스 카드 표기(#1347) 중 **눈으로 못 보는 두 규칙**만 본다.
///
/// 레이아웃은 프리뷰가 보여주므로 테스트하지 않는다. 조용히 틀려도 화면상으로는 멀쩡한 것,
/// 즉 「시리얼이 원본 ID 를 흘리는가」와 「앞면 라벨이 화면에 남은 항목만 화면 순서대로
/// 읽는가」(#1363 · #1374) 두 가지만 단정한다.
@Suite("라이선스 카드 표기")
struct CardLicenseFaceTests {

    // MARK: - 1. 뒷면 시리얼

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

    private func card(memberId: String, part: UMCPartType = .front(type: .ios)) -> MyCard {
        MyCard(
            memberId: memberId,
            name: "김유엠",
            nickname: "유엠디",
            part: part,
            generation: "12",
            university: "한양대학교",
            email: nil,
            github: nil,
            linkedIn: nil,
            blog: nil,
            avatarURL: nil
        )
    }

    private enum Constants {
        /// 서버 회원 ID 는 짧은 정수 문자열일 수도, UUID 일 수도 있다. 포함 여부 검사가
        /// 우연히 통과하지 않도록 충분히 긴 값을 쓴다.
        static let memberId = "7F3C1A22-9B0D-4E68-BC51-2D0A6E4F91AB"
    }
}
