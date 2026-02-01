//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    // MARK: - Property

    var searchText: String = ""
    var isRecruiting: Bool = false
    var selectedMenu: CommunityMenu = .all

    var items: Loadable<[CommunityItemModel]> = .loaded(mockItems)
}

// MARK: - Mock
private let mockItems: [CommunityItemModel] = [
    .init(userId: 1, category: .hobby, title: "질문 있습니다", content: "질문 있어요!", profileImage: nil, userName: "김서버", part: "Server", createdAt: "방금 전", likeCount: 5, commentCount: 3),
    .init(userId: 1, category: .question, title: "질문 있습니다", content: "질문 있어요!", profileImage: nil, userName: "김서버", part: "Server", createdAt: "방금 전", likeCount: 5, commentCount: 3),
]
