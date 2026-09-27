//
//  NoticePostRequestDTOTests.swift
//  NoticeDataTests
//
//  Created by euijjang97 on 9/27/26.
//

import Foundation
import NoticeDomain
import Testing
import UMCFoundation
@testable import NoticeData

@Suite("공지 생성 대상 요청 직렬화")
struct NoticePostRequestDTOTests {
    @Test(
        "일반 공지 대상에는 CHALLENGER 탭을 전송한다",
        arguments: [
            (0, nil as Int?, nil as Int?),
            (7, nil as Int?, nil as Int?),
            (7, 3 as Int?, nil as Int?),
            (7, nil as Int?, 5 as Int?)
        ]
    )
    func encodesChallengerTab(gisuId: Int, chapterId: Int?, schoolId: Int?) throws {
        let target = TargetInfoDTO(targetInfo: NoticeTargetInfo(
            gisuId: String(gisuId),
            chapterId: chapterId.map(String.init),
            schoolId: schoolId.map(String.init),
            parts: nil,
            noticeTab: nil
        ))

        let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(target))
            as? [String: Any])
        #expect(json["targetNoticeTab"] as? String == "CHALLENGER")
        #expect(json["targetGisuId"] as? Int == (gisuId > 0 ? gisuId : nil))
        #expect(json["targetChapterId"] as? Int == chapterId)
        #expect(json["targetSchoolId"] as? Int == schoolId)
        #expect(json.keys.contains("targetParts"))
    }

    @Test("파트 공지 대상에도 CHALLENGER 탭과 파트를 전송한다")
    func encodesPartTarget() throws {
        let part = UMCPartType.front(type: .ios)
        let target = TargetInfoDTO(targetInfo: NoticeTargetInfo(
            gisuId: "7",
            chapterId: nil,
            schoolId: nil,
            parts: [part],
            noticeTab: nil
        ))

        let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(target))
            as? [String: Any])
        #expect(json["targetNoticeTab"] as? String == "CHALLENGER")
        #expect(json["targetParts"] as? [String] == [part.apiValue])
    }

    @Test("운영진 공지 대상에는 선택한 탭을 전송한다", arguments: StaffNoticeTab.allCases)
    func encodesStaffTab(_ tab: StaffNoticeTab) throws {
        let target = TargetInfoDTO(targetInfo: NoticeTargetInfo(
            gisuId: "7",
            chapterId: nil,
            schoolId: nil,
            parts: nil,
            noticeTab: tab.rawValue
        ))

        let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(target))
            as? [String: Any])
        #expect(json["targetNoticeTab"] as? String == tab.rawValue)
    }
}
