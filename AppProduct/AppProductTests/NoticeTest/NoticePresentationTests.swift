//
//  NoticePresentationTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/10/26.
//

@testable import AppProduct
import Foundation
import Testing

struct NoticePresentationTests {

    // MARK: - Tag Tests

    @Test("전체 기수 공지는 모든 기수 태그만 노출한다")
    func allGenerationNoticeUsesSingleTag() {
        let model = NoticeItemModel(
            generation: 0,
            scope: .central,
            category: .general,
            mustRead: false,
            isAlert: false,
            date: Date(),
            title: "공지",
            content: "내용",
            writer: "작성자",
            links: [],
            images: [],
            vote: nil,
            viewCount: 0,
            targetsAllGenerations: true
        )

        #expect(model.tags.map { $0.text } == ["모든 기수"])
    }

    @Test("공지 리스트 태그는 기수, 지부/교내, 파트 순서를 유지한다")
    func noticeListTagOrderIsGenerationScopePart() {
        let model = NoticeItemModel(
            generation: 9,
            scope: .branch,
            category: .part(.front(type: .ios)),
            mustRead: false,
            isAlert: false,
            date: Date(),
            title: "공지",
            content: "내용",
            writer: "작성자",
            links: [],
            images: [],
            vote: nil,
            viewCount: 0,
            scopeDisplayName: "Ain"
        )

        #expect(model.tags.map { $0.text } == ["9기", "Ain", "iOS"])
    }

    @Test("공지 상세 태그는 targetInfo의 지부명을 사용한다")
    func detailTagsUseResolvedBranchName() {
        let audience = NoticeTargetInfoDTO(
            targetGisu: "9",
            targetGisuId: "3",
            targetChapterId: "14",
            targetSchoolId: nil,
            targetChapterName: "Ain",
            targetSchoolName: nil,
            chapterName: nil,
            schoolName: nil,
            targetParts: [.front(type: .ios)]
        )
        .toTargetAudience(scope: .branch)

        let detail = NoticeDetail(
            id: "1",
            generation: 9,
            scope: .branch,
            category: .part(.front(type: .ios)),
            isMustRead: false,
            title: "공지",
            content: "내용",
            authorID: "1",
            authorName: "작성자",
            authorImageURL: nil,
            createdAt: Date(),
            updatedAt: nil,
            targetAudience: audience,
            hasPermission: false,
            images: [],
            links: [],
            vote: nil
        )

        #expect(detail.tags.map { $0.text } == ["9기", "Ain", "iOS"])
    }

    // MARK: - Detail Mapping Tests

    @Test("공지 상세 작성자명은 authorName이 비어 있으면 authorNickname으로 폴백한다")
    func noticeDetailUsesNicknameFallbackWhenAuthorNameIsMissing() throws {
        let json = """
        {
          "id": "1",
          "title": "공지",
          "content": "내용",
          "shouldSendNotification": true,
          "viewCount": "0",
          "createdAt": "2026-03-11T10:00:00Z",
          "updatedAt": null,
          "targetInfo": {
            "targetGisu": "9",
            "targetGisuId": "3",
            "targetChapterId": null,
            "targetSchoolId": null,
            "targetParts": []
          },
          "authorChallengerId": "11",
          "authorMemberId": "22",
          "authorNickname": "제옹",
          "authorName": "   ",
          "authorProfileImageUrl": null,
          "vote": null,
          "images": [],
          "links": [],
          "scope": "CENTRAL",
          "category": "GENERAL",
          "isMustRead": false,
          "hasPermission": false
        }
        """

        let dto = try JSONDecoder().decode(NoticeDetailDTO.self, from: Data(json.utf8))
        let detail = dto.toDomain()

        #expect(detail.authorName == "제옹")
    }
}
