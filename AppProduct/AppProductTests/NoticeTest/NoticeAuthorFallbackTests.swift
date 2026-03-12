//
//  NoticeAuthorFallbackTests.swift
//  AppProductTests
//
//  Created by Codex on 3/13/26.
//

@testable import AppProduct
import Foundation
import Testing

struct NoticeAuthorFallbackTests {

    @Test("공지 리스트는 authorName이 없으면 알 수 없음으로 표시한다")
    func noticeListFallsBackToUnknownWhenAuthorNameIsMissing() throws {
        let data = Data(
            """
            {
              "id": "1",
              "title": "공지",
              "content": "내용",
              "shouldSendNotification": false,
              "viewCount": "10",
              "createdAt": "2026-03-13T00:00:00Z",
              "targetInfo": {
                "targetGisuId": "1",
                "targetChapterId": null,
                "targetSchoolId": null,
                "targetParts": []
              },
              "authorChallengerId": "1",
              "authorMemberId": "1",
              "authorNickname": "닉네임",
              "authorName": null
            }
            """.utf8
        )

        let dto = try JSONDecoder().decode(NoticeDTO.self, from: data)
        let model = dto.toItemModel()

        #expect(model.writer == "알 수 없음")
    }

    @Test("공지 상세는 authorName이 없으면 알 수 없음으로 표시한다")
    func noticeDetailFallsBackToUnknownWhenAuthorNameIsMissing() throws {
        let data = Data(
            """
            {
              "id": "1",
              "title": "공지",
              "content": "내용",
              "shouldSendNotification": false,
              "viewCount": "10",
              "createdAt": "2026-03-13T00:00:00Z",
              "updatedAt": null,
              "targetInfo": {
                "targetGisuId": "1",
                "targetChapterId": null,
                "targetSchoolId": null,
                "targetParts": []
              },
              "authorChallengerId": "1",
              "authorMemberId": "1",
              "authorNickname": "닉네임",
              "authorName": null,
              "authorProfileImageUrl": null,
              "vote": null,
              "images": [],
              "links": [],
              "scope": "CENTRAL",
              "category": "GENERAL",
              "isMustRead": false,
              "hasPermission": false
            }
            """.utf8
        )

        let dto = try JSONDecoder().decode(NoticeDetailDTO.self, from: data)
        let detail = dto.toDomain()

        #expect(detail.authorName == "알 수 없음")
        #expect(detail.defaultAuthorDisplayName == "알 수 없음")
    }
}
