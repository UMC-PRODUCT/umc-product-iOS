//
//  CommunityCommentResponse.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

struct CommentDTO: Codable {
    let commentId: Int
    let postId: Int
    let challengerId: Int
    let challengerName: String
    let challengerProfileImage: String?
    let challengerPart: UMCPartType
    let content: String
    let createdAt: String
    let isAuthor: Bool
}

extension CommentDTO {
    func toCommentModel() -> CommunityCommentModel {
        return CommunityCommentModel(
            commentId: commentId,
            userId: challengerId,
            profileImage: challengerProfileImage,
            userName: challengerName,
            content: content,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            isAuthor: isAuthor
        )
    }
}

extension CommentDTO {
    func toCommentModel() -> CommunityCommentModel {
        return CommunityCommentModel(
            userId: challengerId,
            profileImage: nil,
            userName: challengerName,
            content: content,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
        )
    }
}
