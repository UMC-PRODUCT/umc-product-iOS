//
//  CommunityCommentResponse.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

struct CommentResponse: Codable {
    let id: Int
    let postId: Int
    let challengerId: Int
    let challengerName: String
    let content: String
    let createdAt: String
}
