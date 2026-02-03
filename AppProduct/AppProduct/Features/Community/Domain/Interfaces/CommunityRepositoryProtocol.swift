//
//  CommunityRepositoryProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

// MARK: - Protocol

/// 커뮤니티 데이터 접근 인터페이스
protocol CommunityRepositoryProtocol {
    /// 명예의전당 아이템 조회
    func fetchFameItems() async throws -> [CommunityFameItemModel]
    
    /// 커뮤니티 게시글 조회
    func fetchCommunityItems() async throws -> [CommunityItemModel]
    
    /// 커뮤니티 게시글 작성
    func createPost(request: CreatePostRequest) async throws -> CommunityItemModel
    
    /// 커뮤니티 댓글 조회
    func fetchComments(postId: Int) async throws -> [CommunityCommentModel]
}

// MARK: - Request

struct CreatePostRequest {
    let category: CommunityItemCategory
    let title: String
    let content: String
    
    let date: Date?
    let maxParticipants: Int?
    let place: PlaceSearchInfo?
    let link: String?
}
