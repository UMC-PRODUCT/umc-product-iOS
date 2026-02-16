//
//  CommunityPostResponseDTO.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

import Foundation

// MARK: - Post Search

/// 게시글 검색 응답 DTO
/// `GET /api/v1/posts/search`
struct PostSearchResponse: Codable {
    let postId: Int
    let title: String
    let contentPreview: String
    let category: String
    let likeCount: Int
    let createdAt: String
    let matchType: String
}

// MARK: - 1. 공통 게시글 DTO (상세 조회용)
struct PostDetailDTO: Codable {
    let postId: Int
    let title: String
    let content: String
    let category: CommunityItemCategory
    let authorId: Int
    let authorName: String
    let authorPart: UMCPartType?
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let scrapCount: Int?
    let isLiked: Bool
    let isScrapped: Bool?
    let lightningInfo: LightningInfo?

    enum CodingKeys: String, CodingKey {
        case postId, title, content, category, authorId, authorName, commentCount, likeCount, scrapCount, isLiked, isScrapped, lightningInfo
        case authorPart = "userPart"
        case createdAt = "writeTime"
    }
}

// MARK: - 2. 리스트 내 개별 항목 DTO
struct PostListItemDTO: Codable {
    let postId: Int
    let title: String
    let content: String
    let category: CommunityItemCategory
    let authorId: Int
    let authorName: String
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let lightningInfo: LightningInfo?
}

// MARK: - 3. 공통 번개 정보
struct LightningInfo: Codable {
    let meetAt: String
    let location: String
    let maxParticipants: Int
    let openChatUrl: String
}

// 리스트 항목 변환
extension PostListItemDTO {
    func toCommunityItemModel() -> CommunityItemModel {
        return CommunityItemModel(
            postId: postId,
            userId: authorId,
            category: category,
            title: title,
            content: content,
            profileImage: nil,
            userName: authorName,
            part: .pm, // 임시
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: 0,
            isLiked: isLiked,
            lightningInfo: nil
        )
    }
}

// 상세 정보 변환
extension PostDetailDTO {
    func toCommunityItemModel() -> CommunityItemModel {
        return CommunityItemModel(
            postId: postId,
            userId: authorId,
            category: category,
            title: title,
            content: content,
            profileImage: nil,
            userName: authorName,
            part: authorPart ?? .pm, // 임시
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: scrapCount ?? 0,
            isLiked: isLiked,
            lightningInfo: nil
        )
    }
}

// MARK: - 좋아요/스크랩
struct CommunityLikeDTO: Codable {
    let liked: Bool
    let likeCount: Int
}

struct CommunityScrapDTO: Codable {
    let scrapped: Bool
    let scrapCount: Int
}
