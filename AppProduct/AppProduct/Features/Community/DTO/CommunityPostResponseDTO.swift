//
//  CommunityPostResponseDTO.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

import Foundation

// MARK: - 1. 공통 게시글 DTO (상세 조회용)
struct PostDetailDTO: Codable {
    let postId: Int
    let title: String
    let content: String
    let category: CommunityItemCategory
    let authorId: Int
    let authorName: String
    let authorProfileImage: String?
    let authorPart: UMCPartType
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let scrapCount: Int?
    let isLiked: Bool
    let isScrapped: Bool?
    let isAuthor: Bool
    let lightningInfo: LightningInfoDTO

    enum CodingKeys: String, CodingKey {
            case postId, title, content, category, authorId, authorName, authorProfileImage, authorPart
            case commentCount, likeCount, scrapCount, isLiked, isScrapped, isAuthor, lightningInfo
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
    let authorProfileImage: String?
    let authorPart: UMCPartType
    let createdAt: String
    let commentCount: Int
    let likeCount: Int
    let isLiked: Bool
    let isAuthor: Bool
    let lightningInfo: LightningInfoDTO
}

// MARK: - 3. 공통 번개 정보
struct LightningInfoDTO: Codable {
    let meetAt: String
    let location: String
    let maxParticipants: Int
    let openChatUrl: String
    
    func toModel() -> CommunityLightningInfo {
        return CommunityLightningInfo(
            meetAt: ISO8601DateFormatter().date(from: meetAt) ?? Date(),
            location: location,
            maxParticipants: maxParticipants,
            openChatUrl: openChatUrl
        )
    }
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
            part: authorPart,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: 0,
            isLiked: isLiked,
            isAuthor: isAuthor,
            lightningInfo: lightningInfo.toModel()
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
            profileImage: authorProfileImage,
            userName: authorName,
            part: authorPart,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: scrapCount ?? 0,
            isLiked: isLiked,
            isAuthor: isAuthor,
            lightningInfo: lightningInfo.toModel()
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
