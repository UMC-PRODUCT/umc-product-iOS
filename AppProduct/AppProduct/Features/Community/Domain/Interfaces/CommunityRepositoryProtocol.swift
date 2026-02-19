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
    func getTrophies(query: TrophyListQuery) async throws -> [CommunityFameItemModel]
    
    /// 커뮤니티 게시글 조회
    func getPosts(query: PostListQuery) async throws -> (
        items: [CommunityItemModel],
        hasNext: Bool
    )
    
    /// 커뮤니티 검색
    func getSearch(query: PostSearchQuery) async throws -> (
        items: [CommunityItemModel],
        hasNext: Bool
    )
}
