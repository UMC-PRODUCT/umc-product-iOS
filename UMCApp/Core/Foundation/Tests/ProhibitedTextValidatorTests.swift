//
//  ProhibitedTextValidatorTests.swift
//  UMCFoundationTests
//
//  Created by euijjang97 on 10/29/26.
//

import Foundation
import Testing
@testable import UMCFoundation

@Suite("공개 입력 금지어 검증")
struct ProhibitedTextValidatorTests {
    @Test("운영 목록의 모든 원문과 글자 사이 공백 삽입을 차단한다")
    func rejectsEveryCatalogEntry() {
        #expect(ProhibitedTextCatalog.entries.count == 135)
        #expect(Set(ProhibitedTextCatalog.entries.map(\.id)).count == 135)
        for entry in ProhibitedTextCatalog.entries {
            #expect(ProhibitedTextValidator.containsProhibitedText(entry.text))
            let spaced = entry.text.map(String.init).joined(separator: " ")
            #expect(ProhibitedTextValidator.containsProhibitedText(spaced))
        }
    }

    @Test("정규화·띄어쓰기·활용형을 검사한다", arguments: [
        "NIGGER", "ＮＩＧＧＥＲ", "씨\u{200B}발", "씨\u{FE0F}발",
        "씨발", "씨\t발", "칼로 찌르겠다", "개인정보 뿌리겠다", "개년아", "니거",
        "자살해라", "이런씨발", "아니거든 니거"
    ])
    func rejectsNormalizedVariants(_ text: String) {
        #expect(ProhibitedTextValidator.containsProhibitedText(text))
    }

    @Test("정상 문장과 문장 경계는 합쳐 검사하지 않는다", arguments: [
        "안녕하세요", "아니거든", "그런 건 아니거든요", "3개년 계획", "5개년도 사업",
        "장애인 접근성 개선", "성적 지향에 따른 차별 금지", "백수", "종교의 자유",
        "씨. 발아율을 조사합니다", "씨\n발", "개발자", "가족 👨‍👩‍👧", ""
    ])
    func allowsOrdinaryText(_ text: String) {
        #expect(!ProhibitedTextValidator.containsProhibitedText(text))
    }

    @Test("검증 오류는 금지 원문을 노출하지 않는 사용자 안내를 제공한다")
    func providesValidationError() {
        #expect(throws: AppError.validation(.invalidValue(
            field: "메시지", reason: ProhibitedTextValidator.userMessage
        ))) {
            try ProhibitedTextValidator.validate("씨발", field: "메시지")
        }
    }
}
