//
//  CommunityCommentResponse.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

struct CommentDTO: Codable {
    let commentId: String
    let postId: String
    let challengerId: String?
    let challengerName: String?
    let challengerNickname: String?
    let challengerProfileImage: String?
    let challengerPart: String?
    let content: String
    let createdAt: String
    let isAuthor: Bool

    private enum CodingKeys: String, CodingKey {
        case commentId
        case postId
        case challengerId
        case challengerName
        case challengerNickname
        case challengerProfileImage
        case challengerPart
        case content
        case createdAt
        case isAuthor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commentId = try container.decodeFlexibleString(forKey: .commentId)
        postId = try container.decodeFlexibleString(forKey: .postId)
        challengerId = container.decodeFlexibleOptionalString(forKey: .challengerId)
        challengerName = try container.decodeIfPresent(String.self, forKey: .challengerName)
        challengerNickname = try container.decodeIfPresent(String.self, forKey: .challengerNickname)
        challengerProfileImage = try container.decodeIfPresent(String.self, forKey: .challengerProfileImage)
        challengerPart = try container.decodeIfPresent(String.self, forKey: .challengerPart)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        isAuthor = try container.decode(Bool.self, forKey: .isAuthor)
    }
}

extension CommentDTO {
    func toCommentModel() -> CommunityCommentModel {
        return CommunityCommentModel(
            commentId: Int(commentId) ?? 0,
            userId: challengerId.flatMap(Int.init) ?? 0,
            profileImage: challengerProfileImage,
            userName: resolvedCommentAuthorName(challengerName: challengerName),
            userNickname: challengerNickname,
            content: content,
            createdAt: ServerDateTimeConverter.parseUTCDateTime(createdAt) ?? Date(),
            isAuthor: isAuthor
        )
    }
}

private func resolvedCommentAuthorName(challengerName: String?) -> String {
    let trimmedChallengerName = challengerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    guard !trimmedChallengerName.isEmpty else {
        return "알 수 없음"
    }

    return trimmedChallengerName
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected String/Int/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeFlexibleOptionalString(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        return nil
    }
}
