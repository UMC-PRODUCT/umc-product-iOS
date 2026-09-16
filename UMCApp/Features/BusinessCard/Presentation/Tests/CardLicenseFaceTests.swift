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
/// 즉 「시리얼이 원본 ID 를 흘리는가」와 「못 센 칸이 0 으로 둔갑하는가」 두 가지만 단정한다.
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

    // MARK: - 2. 기록 슬롯

    /// `nil` 은 「0」이 아니라 「아직 못 셌다」다 (#1222). 0 으로 그리면 통신이 끊긴 카드가
    /// 「스터디 0건」이라고 단언한다.
    @Test("못 센 칸은 0 이 아니라 - 로 그린다", arguments: CardRecordSlot.allCases)
    func emptySlotRendersDash(_ slot: CardRecordSlot) {
        #expect(slot.displayValue(in: .empty) == "-")
        #expect(slot.spokenPhrase(in: .empty) == nil)
    }

    /// `"50+"` 같은 서버 잘림 표기를 숫자로 바꾸거나 잘라내지 않는다 (핵심규칙 #2).
    @Test("센 칸은 서버 문자열을 그대로 싣는다")
    func countedSlotKeepsServerString() {
        let stat = ActivityStat(
            receivedCardCount: "50+",
            studyCount: "3",
            activityCount: "0",
            bookmarkCount: "12"
        )

        #expect(CardRecordSlot.cards.displayValue(in: stat) == "50+")
        // 서버가 진짜로 0 을 세어 준 경우는 "-" 가 아니라 "0" 이다.
        #expect(CardRecordSlot.activity.displayValue(in: stat) == "0")
        #expect(CardRecordSlot.study.spokenPhrase(in: stat) == "스터디 3건")
    }

    // MARK: - Helper

    private func card(memberId: String) -> MyCard {
        MyCard(
            memberId: memberId,
            name: "김유엠",
            nickname: "유엠디",
            part: .front(type: .ios),
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
