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
    let challengerId: String
    let challengerName: String
    let challengerProfileImage: String?
    let challengerPart: String
    let content: String
    let createdAt: String
    let isAuthor: Bool
}

extension CommentDTO {
    func toCommentModel() -> CommunityCommentModel {
        return CommunityCommentModel(
            commentId: Int(commentId) ?? 0,
            userId: Int(challengerId) ?? 0,
            profileImage: challengerProfileImage,
            userName: challengerName,
            content: content,
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            isAuthor: isAuthor
        )
    }
}
