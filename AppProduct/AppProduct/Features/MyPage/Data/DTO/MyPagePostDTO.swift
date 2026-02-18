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
    let authorPart: UMCPartType
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let isAuthor: Bool
    let lightningInfo: LightningInfoDTO?

    private enum CodingKeys: String, CodingKey {
        case postId
        case title
        case content
        case category
        case authorId
        case authorName
        case authorProfileImage
        case authorPart
        case createdAt
        case commentCount
        case likeCount
        case isLiked
        case isAuthor
        case lightningInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = try container.decodeFlexibleInt(forKey: .postId)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        category = try container.decode(String.self, forKey: .category)
        authorId = try container.decodeFlexibleInt(forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        authorProfileImage = try container.decodeIfPresent(String.self, forKey: .authorProfileImage)
        authorPart = try container.decode(UMCPartType.self, forKey: .authorPart)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        commentCount = try container.decodeFlexibleInt(forKey: .commentCount)
        likeCount = try container.decodeFlexibleInt(forKey: .likeCount)
        isLiked = try container.decode(Bool.self, forKey: .isLiked)
        isAuthor = try container.decode(Bool.self, forKey: .isAuthor)
        lightningInfo = try container.decodeIfPresent(LightningInfoDTO.self, forKey: .lightningInfo)
    }
}

struct MyPagePostPageDTO<T: Codable>: Codable {
    let content: [T]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool

    private enum CodingKeys: String, CodingKey {
        case content
        case page
        case size
        case totalElements
        case totalPages
        case hasNext
        case hasPrevious
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([T].self, forKey: .content)
        page = try container.decodeFlexibleInt(forKey: .page)
        size = try container.decodeFlexibleInt(forKey: .size)
        totalElements = try container.decodeFlexibleInt(forKey: .totalElements)
        totalPages = try container.decodeFlexibleInt(forKey: .totalPages)
        hasNext = try container.decode(Bool.self, forKey: .hasNext)
        hasPrevious = try container.decode(Bool.self, forKey: .hasPrevious)
    }
}
