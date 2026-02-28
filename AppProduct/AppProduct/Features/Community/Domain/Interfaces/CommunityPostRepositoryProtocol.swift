//
//  CommunityPostRepositoryProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

// MARK: - Protocol

// 커뮤니티 게시글 인터페이스
protocol CommunityPostRepositoryProtocol {
    /// 게시글 작성
    func postPosts(
        request: PostRequestDTO
    ) async throws

    /// 번개글 작성
    func postLightning(
        request: CreateLightningPostRequestDTO
    ) async throws

    /// 게시글 수정
    func patchPosts(
        postId: Int,
        request: PostRequestDTO
    ) async throws
    
    /// 번개글 수정
    func patchLightning(
        postId: Int,
        request: CreateLightningPostRequestDTO
    ) async throws
}
