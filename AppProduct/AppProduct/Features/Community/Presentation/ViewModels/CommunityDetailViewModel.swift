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

    let postItem: CommunityItemModel
    var comments: Loadable<[CommunityCommentModel]> = .loaded(mockComments)

    // MARK: - Init

    init(postItem: CommunityItemModel) {
        self.postItem = postItem
    }
}

// MARK: - Mock

private let mockComments: [CommunityCommentModel] = [
    .init(userId: 1, profileImage: nil, userName: "유저1", content: "저 참여하고 싶습니다! 아직 자리 있나요?", createdAt: "방금전"),
    .init(userId: 2, profileImage: nil, userName: "유저2", content: "저도 궁금해요!", createdAt: "5분 전")
]
