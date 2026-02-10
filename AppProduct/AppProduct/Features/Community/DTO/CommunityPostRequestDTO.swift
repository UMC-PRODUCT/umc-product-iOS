
//
//  CommunityPostRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Post Search

/// 게시글 검색 쿼리 DTO
///
/// `GET /api/v1/posts/search` 쿼리 파라미터
struct PostSearchQuery: Encodable {
    /// 검색 키워드
    let keyword: String
    /// 페이지 (0부터 시작)
    let page: Int
    /// 페이지 크기
    let size: Int
    
    var toParameters: [String: Any] {
        [
            "keyword": keyword,
            "page": page,
            "size": size
        ]
    }
}

// MARK: - Post List

/// 게시글 목록 조회 쿼리 DTO
///
/// `GET /api/v1/posts` 쿼리 파라미터
struct PostListQuery: Encodable {
    /// 카테고리 (LIGHTNING, QUESTION, FREE, etc.)
    let category: String?
    /// 페이지 (0부터 시작)
    let page: Int
    /// 페이지 크기
    let size: Int
    
    var toParameters: [String: Any] {
        var params: [String: Any] = [
            "page": page,
            "size": size
        ]
        if let category = category {
            params["category"] = category
        }
        return params
    }
}

// MARK: - Create/Update Post

/// 게시글 생성/수정 요청 DTO
///
/// `POST /api/v1/posts`, `PATCH /api/v1/posts/{postId}` 요청 Body
struct PostRequestDTO: Encodable {
    let title: String
    let content: String
    let category: String
}

// MARK: - Create Lightning Post

/// 번개글 생성 요청 DTO
///
/// `POST /api/v1/posts/lightning` 요청 Body
struct CreateLightningPostRequestDTO: Encodable {
    let title: String
    let content: String
    let meetAt: String
    let location: String
    let maxParticipants: Int
    let openChatUrl: String
}
