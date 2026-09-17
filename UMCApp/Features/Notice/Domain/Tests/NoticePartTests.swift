//
//  NoticePartTests.swift
//  NoticeDomainTests
//
//  Created by euijjang97 on 9/17/26.
//

import Testing
import UMCFoundation
@testable import NoticeDomain

@Suite("NoticePart — 서버 파트 값 ↔ 공지 파트 매핑")
struct NoticePartTests {

    @Test("모든 공지 파트가 apiValue 를 거쳐 같은 파트로 복원된다")
    func allCasesRoundTripThroughAPIValue() {
        for part in NoticePart.allCases {
            #expect(NoticePart(apiValue: part.umcPartType.apiValue) == part)
        }
    }

    @Test("PE 서버 값이 공지 파트로 매핑되고 표시명·아이콘이 UMCPartType 과 같다")
    func productEngineerAPIValueMapsToNoticePart() {
        let expectations: [(apiValue: String, part: NoticePart)] = [
            ("WEB_PRODUCT_ENGINEER", .webProductEngineer),
            ("MOBILE_PRODUCT_ENGINEER", .mobileProductEngineer),
        ]

        for (apiValue, part) in expectations {
            #expect(NoticePart(apiValue: apiValue) == part)
            #expect(part.umcPartType.apiValue == apiValue)
            #expect(part.displayName == part.umcPartType.name)
            #expect(part.iconName == part.umcPartType.icon)
        }
    }

    @Test("공지 파트가 아닌 값은 nil 이다", arguments: ["ADMIN", "", "UNKNOWN"])
    func nonNoticePartAPIValueReturnsNil(apiValue: String) {
        #expect(NoticePart(apiValue: apiValue) == nil)
    }
}
