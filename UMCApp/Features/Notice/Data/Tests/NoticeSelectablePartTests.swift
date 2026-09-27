//
//  NoticeSelectablePartTests.swift
//  NoticeDataTests
//
//  Created by euijjang97 on 9/27/26.
//

import Foundation
import Testing
import NoticeDomain
import CoreNetwork
@testable import NoticeData

@Suite("선택 가능한 공지 파트")
struct NoticeSelectablePartTests {
    @Test("서버 응답의 순서와 표시명을 유지하며 선택 값은 API 이름과 일치한다")
    func decodesSelectableParts() throws {
        let data = Data("""
        {"success":true,"result":[
          {"name":"PLAN","displayName":"기획"},
          {"name":"DESIGN","displayName":"디자인"},
          {"name":"WEB_PRODUCT_ENGINEER","displayName":"웹 프로덕트 엔지니어"},
          {"name":"MOBILE_PRODUCT_ENGINEER","displayName":"모바일 프로덕트 엔지니어"}
        ]}
        """.utf8)
        let response = try JSONDecoder().decode(
            APIResponse<[NoticeSelectablePartDTO]>.self,
            from: data
        )
        let result = try response.unwrap().compactMap {
            NoticeSelectablePart(name: $0.name, displayName: $0.displayName)
        }

        #expect(result.map(\.name) == [
            "PLAN", "DESIGN", "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER"
        ])
        #expect(result.map(\.displayName) == [
            "기획", "디자인", "웹 프로덕트 엔지니어", "모바일 프로덕트 엔지니어"
        ])
        #expect(result.map { $0.part.umcPartType.apiValue } == result.map(\.name))
        #expect(NoticeSelectablePart(name: "ADMIN", displayName: "운영진") == nil)
    }
}
