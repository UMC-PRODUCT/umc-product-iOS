//
//  MyPageRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// MyPage 데이터 접근 Repository Protocol
protocol MyPageRepositoryProtocol: Sendable {

    /// 내 프로필 조회
    func fetchMyProfile() async throws -> ProfileData

    /// 프로필 이미지를 업로드하고 회원 프로필에 반영합니다.
    ///
    /// 내부 흐름:
    /// prepare-upload -> signed URL 업로드 -> confirm -> member patch
    func updateProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData

    /// 회원 탈퇴를 수행합니다.
    func deleteMember() async throws

    /// 내가 쓴 글 목록을 조회합니다.
    func fetchMyPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage

    /// 댓글 단 글 목록을 조회합니다.
    func fetchCommentedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage

    /// 스크랩한 글 목록을 조회합니다.
    func fetchScrappedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage

    /// 약관 타입으로 약관 링크 정보를 조회합니다.
    func fetchTerms(termsType: String) async throws -> MyPageTerms
}
