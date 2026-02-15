//
//  MyPagePostDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

struct MyPagePostListQuery {
    let page: Int
    let size: Int
    let sort: [String]

    init(
        page: Int = 0,
        size: Int = 20,
        sort: [String] = ["createdAt,DESC"]
    ) {
        self.page = page
        self.size = size
        self.sort = sort
    }

    var queryItems: [String: Any] {
        var params: [String: Any] = [
            "page": page,
            "size": size
        ]
        if !sort.isEmpty {
            params["sort"] = sort
        }
        return params
    }
}

struct MyPagePostResponseDTO: Codable {
    let postId: Int
    let title: String
    let content: String
    let category: String
    let authorId: Int
    let authorName: String
    let authorProfileImage: String?
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let lightningInfo: MyPageLightningInfoDTO?
}

struct MyPageLightningInfoDTO: Codable {
    let meetAt: String
    let location: String
    let maxParticipants: Int
    let openChatUrl: String
}

struct MyPagePostPageDTO<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}
