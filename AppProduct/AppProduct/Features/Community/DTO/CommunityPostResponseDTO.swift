//
//  CommunityPostResponseDTO.swift
//  AppProduct
//
//  Created by 김미주 on 2/14/26.
//

import Foundation

// MARK: - 1. 공통 게시글 DTO (상세 조회용)
struct PostDetailDTO: Codable {
    let postId: String
    let title: String
    let content: String
    let category: String
    let authorId: String
    let authorName: String
    let authorProfileImage: String?
    let authorPart: String?
    let lightningInfo: LightningInfoDTO?
    let commentCount: String
    let writeTime: String
    let likeCount: String
    let isLiked: Bool
    let isAuthor: Bool
    let scrapCount: String
    let isScrapped: Bool
}

// MARK: - 2. 리스트 내 개별 항목 DTO
struct PostListItemDTO: Codable {
    let postId: String
    let title: String
    let content: String
    let category: String
    let authorId: String
    let authorName: String
    let authorProfileImage: String?
    let authorPart: String?
    let createdAt: String
    let commentCount: String
    let likeCount: String
    let isLiked: Bool
    let isAuthor: Bool
    let lightningInfo: LightningInfoDTO?
}

// MARK: - 3. 공통 번개 정보
struct LightningInfoDTO: Codable {
    let meetAt: String
    let location: String
    let maxParticipants: String
    let openChatUrl: String

    private enum CodingKeys: String, CodingKey {
        case meetAt
        case location
        case maxParticipants
        case openChatUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meetAt = try container.decode(String.self, forKey: .meetAt)
        location = try container.decode(String.self, forKey: .location)
        openChatUrl = try container.decode(String.self, forKey: .openChatUrl)

        if let stringValue = try? container.decode(String.self, forKey: .maxParticipants) {
            maxParticipants = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .maxParticipants) {
            maxParticipants = String(intValue)
        } else {
            maxParticipants = "0"
        }
    }
    
    func toModel() -> CommunityLightningInfo {
        let parsedMeetAt = DateParser.iso8601WithFractional.date(from: meetAt)
            ?? DateParser.iso8601.date(from: meetAt)
            ?? DateParser.iso8601WithoutTimezone.date(from: meetAt)
            ?? Date()

        return CommunityLightningInfo(
            meetAt: parsedMeetAt,
            location: location,
            maxParticipants: Int(maxParticipants) ?? 0,
            openChatUrl: openChatUrl
        )
    }
}

private enum DateParser {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let iso8601WithoutTimezone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

// 리스트 항목 변환
extension PostListItemDTO {
    func toCommunityItemModel() -> CommunityItemModel {
        return CommunityItemModel(
            postId: Int(postId) ?? 0,
            userId: Int(authorId) ?? 0,
            category: CommunityItemCategory(apiValue: category) ?? .free,
            title: title,
            content: content,
            profileImage: authorProfileImage,
            userName: authorName,
            part: UMCPartType(apiValue: authorPart ?? "PM") ?? .pm,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: Int(likeCount) ?? 0,
            commentCount: Int(commentCount) ?? 0,
            scrapCount: 0,
            isLiked: isLiked,
            isAuthor: isAuthor,
            lightningInfo: lightningInfo?.toModel(),
        )
    }
}

// 상세 정보 변환
extension PostDetailDTO {
    func toCommunityItemModel() -> CommunityItemModel {
        return CommunityItemModel(
            postId: Int(postId) ?? 0,
            userId: Int(authorId) ?? 0,
            category: CommunityItemCategory(apiValue: category) ?? .free,
            title: title,
            content: content,
            profileImage: authorProfileImage,
            userName: authorName,
            part: UMCPartType(apiValue: authorPart ?? "PM") ?? .pm,
            createdAt: ISO8601DateFormatter().date(from: writeTime) ?? Date(),
            likeCount: Int(likeCount) ?? 0,
            commentCount: Int(commentCount) ?? 0,
            scrapCount: Int(scrapCount) ?? 0,
            isLiked: isLiked,
            isScrapped: isScrapped,
            isAuthor: isAuthor,
            lightningInfo: lightningInfo?.toModel()
        )
    }
}

// MARK: - 좋아요/스크랩
struct CommunityLikeDTO: Codable {
    let liked: Bool
    let likeCount: String
}

struct CommunityScrapDTO: Codable {
    let scrapped: Bool
    let scrapCount: String
}
