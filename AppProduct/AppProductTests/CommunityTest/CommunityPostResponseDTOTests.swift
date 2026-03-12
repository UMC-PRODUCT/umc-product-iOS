//
//  CommunityPostResponseDTOTests.swift
//  AppProductTests
//
//  Created by Codex on 3/12/26.
//

@testable import AppProduct
import Foundation
import Testing

struct CommunityPostResponseDTOTests {

    @Test("게시글 리스트 DTO는 challengerNickname을 authorNickname fallback으로 사용한다")
    func postListItemUsesChallengerNicknameFallback() throws {
        let data = Data(
            """
            {
              "postId": "1",
              "title": "테스트",
              "content": "내용",
              "category": "FREE",
              "authorId": "10",
              "authorName": "정의찬",
              "challengerNickname": "제옹",
              "authorProfileImage": null,
              "authorPart": "SPRINGBOOT",
              "createdAt": "2026-03-12T08:28:00.248106Z",
              "commentCount": "2",
              "likeCount": "1",
              "isLiked": false,
              "isAuthor": false,
              "lightningInfo": null
            }
            """.utf8
        )

        let dto = try JSONDecoder().decode(PostListItemDTO.self, from: data)
        let model = dto.toCommunityItemModel()

        #expect(dto.authorNickname == "제옹")
        #expect(model.displayUserName == "정의찬/제옹")
    }

    @Test("게시글 상세 DTO는 authorNickname이 비어있으면 challengerNickname을 사용한다")
    func postDetailUsesChallengerNicknameWhenAuthorNicknameIsEmpty() throws {
        let data = Data(
            """
            {
              "postId": "1",
              "title": "테스트",
              "content": "내용",
              "category": "FREE",
              "authorId": "10",
              "authorName": "정의찬",
              "authorNickname": "",
              "challengerNickname": "제옹",
              "authorProfileImage": null,
              "authorPart": "SPRINGBOOT",
              "commentCount": "2",
              "writeTime": "2026-03-12T08:28:00.248106Z",
              "likeCount": "1",
              "isLiked": false,
              "isAuthor": false,
              "scrapCount": "0",
              "isScrapped": false,
              "lightningInfo": null
            }
            """.utf8
        )

        let dto = try JSONDecoder().decode(PostDetailDTO.self, from: data)
        let model = dto.toCommunityItemModel()

        #expect(dto.authorNickname == "제옹")
        #expect(model.displayUserName == "정의찬/제옹")
    }
}
