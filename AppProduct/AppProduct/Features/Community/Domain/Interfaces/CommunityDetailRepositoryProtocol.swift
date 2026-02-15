//
//  CommunityDetailRepositoryProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

// 커뮤니티 상세 인터페이스
protocol CommunityDetailRepositoryProtocol {
    /// 게시글 삭제
    func deletePost(postId: Int) async throws
    /// 댓글 삭제
    func deleteComment(postId: Int, commentId: Int) async throws
    /// 댓글 조회
    func getComments(postId: Int) async throws -> [CommunityCommentModel]
    /// 게시글 상세 조회
    func getPostDetail(postId: Int) async throws -> CommunityItemModel
    /// 스크랩
    func postScrap(postId: Int) async throws
    /// 좋아요
    func postLike(postId: Int) async throws
    /// 댓글 작성
    func postComment(postId: Int, request: PostCommentRequest) async throws
}
