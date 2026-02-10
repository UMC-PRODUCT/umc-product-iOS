
//
//  CommunityCommentRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Delete Comment

/// 댓글 삭제 쿼리 DTO
///
/// `DELETE /api/v1/posts/{postId}/comments/{commentId}` 쿼리 파라미터
struct DeleteCommentQuery: Encodable {
    /// 챌린저 ID (예: 작성자 확인용)
    let challengerId: Int
    
    var toParameters: [String: Any] {
        ["challengerId": challengerId]
    }
}
