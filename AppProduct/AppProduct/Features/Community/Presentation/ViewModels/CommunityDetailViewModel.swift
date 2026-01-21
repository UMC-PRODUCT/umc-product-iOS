//
//  CommunityDetailViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import Foundation

@Observable
class CommunityDetailViewModel {
    // MARK: - Property

    private let postId: UUID
    var comments: [CommunityCommentModel] = []

    // MARK: - Init

    init(postId: UUID) {
        self.postId = postId
        loadComments()
    }

    // MARK: - Function

    private func loadComments() {
        // TODO: API 연동 시 postId로 댓글 fetch - [김미주] 26.01.22
        comments = mockComments[abs(postId.hashValue) % mockComments.count]
    }
}

// MARK: - Mock Data

private extension CommunityDetailViewModel {
    var mockComments: [[CommunityCommentModel]] {
        [
            [
                .init(profileImage: nil, userName: "김애플", content: "저 참여하고 싶습니다! 아직 자리 있나요?", createdAt: "10분 전"),
                .init(profileImage: nil, userName: "박애플", content: "저도 참여하고 싶어요!", createdAt: "5분 전")
            ],
            [
                .init(profileImage: nil, userName: "이코딩", content: "저 참여하고 싶습니다! 아직 자리 있나요?", createdAt: "30분 전"),
                .init(profileImage: nil, userName: "최코딩", content: "저 참여하고 싶습니다!", createdAt: "20분 전"),
                .init(profileImage: nil, userName: "정코딩", content: "아직 자리 있나요?", createdAt: "10분 전")
            ],
            [
                .init(profileImage: nil, userName: "이코딩", content: "저도 참여하고 싶어요!", createdAt: "1시간 전")
            ]
        ]
    }
}
