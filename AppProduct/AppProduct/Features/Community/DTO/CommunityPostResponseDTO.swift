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

// MARK: - Post List

/// 게시글 목록 조회 응답, 게시글 생성/수정 응답, 번개글 생성/수정 응답 DTO
/// `GET /api/v1/posts`
/// `POST /api/v1/posts`, `PATCH /api/v1/posts/{postId}`
/// `POST /api/v1/posts/lightning`, `PATCH /api/v1/posts/{postId}/lightning`
struct PostListResponse: Codable {
    let postId: Int
    let title: String
    let content: String
    let category: CommunityItemCategory
    let authorId: Int
    let authorName: String
    let authorProfileImage: String? // 추가요청
    let authorPart: UMCPartType // 추가요청
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let lightningInfo: PostListLightningInfo?
    
    struct PostListLightningInfo: Codable {
        let meetAt: String
        let location: String
        let maxParticipants: Int
        let openChatUrl: String
    }
}

extension PostListResponse {
    func toCommunityItemModel() -> CommunityItemModel {
        let date = ISO8601DateFormatter().date(from: createdAt) ?? Date()
        
        return CommunityItemModel(
            postId: postId,
            userId: authorId,
            category: category,
            title: title,
            content: content,
            profileImage: authorProfileImage,
            userName: authorName,
            part: authorPart,
            createdAt: date,
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: 0,
            isLiked: isLiked
        )
    }
}
