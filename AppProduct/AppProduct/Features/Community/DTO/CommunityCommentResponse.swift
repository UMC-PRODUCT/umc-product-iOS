//
//  CommunityCommentResponse.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

struct CommentDTO: Codable {
    let id: Int
    let postId: Int
    let challengerId: Int
    let challengerName: String
    let content: String
    let createdAt: String
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
