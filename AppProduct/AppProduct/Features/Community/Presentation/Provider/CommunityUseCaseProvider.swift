//
//  CommunityUseCaseProvider.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// Community Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol CommunityUseCaseProviding {
    /// 명예의전당 조회
    var fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol { get }
    /// 커뮤니티 목록 조회
    var fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol { get }
    /// 게시글 검색
    var searchPostUseCase: SearchPostUseCaseProtocol { get }
    /// 게시글 생성
    var createPostUseCase: CreatePostUseCaseProtocol { get }
    /// 번개글 생성
    var createLightningUseCase: CreateLightningUseCaseProtocol { get }
    /// 게시글 수정
    var updatePostUseCase: UpdatePostUseCaseProtocol { get }
    /// 번개글 수정
    var updateLightningUseCase: UpdateLightningUseCaseProtocol { get }
    /// 댓글 조회
    var fetchCommentUseCase: FetchCommentsUseCaseProtocol { get }
    /// 게시글 삭제
    var deletePostUseCase: DeletePostUseCaseProtocol { get }
    /// 댓글 삭제
    var deleteCommentUseCase: DeleteCommentUseCaseProtocol { get }
    /// 게시글 상세 조회
    var fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol { get }
    /// 게시글 스크랩
    var postScrapUseCase: PostScrapUseCaseProtocol { get }
    /// 게시글 좋아요
    var postLikeUseCase: PostLikeUseCaseProtocol { get }
    /// 댓글 작성
    var postCommentUseCase: PostCommentUseCaseProtocol { get }
    /// 게시글 신고
    var reportPostUseCase: ReportPostUseCaseProtocol { get }
    /// 댓글 신고
    var reportCommentUseCase: ReportCommentUseCaseProtocol { get }
}

/// Community UseCase Provider 구현
///
/// CommunityRepository를 직접 주입받아 UseCase들을 생성합니다.
final class CommunityUseCaseProvider: CommunityUseCaseProviding {
    // MARK: - Property

    let fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol
    let fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol
    let searchPostUseCase: SearchPostUseCaseProtocol
    let createPostUseCase: CreatePostUseCaseProtocol
    let createLightningUseCase: CreateLightningUseCaseProtocol
    let updatePostUseCase: UpdatePostUseCaseProtocol
    let updateLightningUseCase: UpdateLightningUseCaseProtocol
    let fetchCommentUseCase: FetchCommentsUseCaseProtocol
    let deletePostUseCase: DeletePostUseCaseProtocol
    let deleteCommentUseCase: DeleteCommentUseCaseProtocol
    let fetchPostDetailUseCase: FetchPostDetailUseCaseProtocol
    let postScrapUseCase: PostScrapUseCaseProtocol
    let postLikeUseCase: PostLikeUseCaseProtocol
    let postCommentUseCase: PostCommentUseCaseProtocol
    let reportPostUseCase: ReportPostUseCaseProtocol
    let reportCommentUseCase: ReportCommentUseCaseProtocol

    // MARK: - Init

    init(
        communityRepository: CommunityRepositoryProtocol,
        communityPostRepository: CommunityPostRepositoryProtocol,
        communityDetailRepository: CommunityDetailRepositoryProtocol
    ) {
        self.fetchFameItemsUseCase = FetchFameItemsUseCase(
            repository: communityRepository
        )
        self.fetchCommunityItemsUseCase = FetchCommunityItemsUseCase(
            repository: communityRepository
        )
        self.searchPostUseCase = SearchPostUseCase(
            repository: communityRepository
        )
        self.createPostUseCase = CreatePostUseCase(
            repository: communityPostRepository
        )
        self.createLightningUseCase = CreateLightningUseCase(
            repository: communityPostRepository
        )
        self.updatePostUseCase = UpdatePostUseCase(
            repository: communityPostRepository
        )
        self.updateLightningUseCase = UpdateLightningUseCase(
            repository: communityPostRepository
        )
        self.fetchCommentUseCase = FetchCommentsUseCase(
            repository: communityDetailRepository
        )
        self.deletePostUseCase = DeletePostUseCase(
            repository: communityDetailRepository
        )
        self.deleteCommentUseCase = DeleteCommentUseCase(
            repository: communityDetailRepository
        )
        self.fetchPostDetailUseCase = FetchPostDetailUseCase(
            repository: communityDetailRepository
        )
        self.postScrapUseCase = PostScrapUseCase(
            repository: communityDetailRepository
        )
        self.postLikeUseCase = PostLikeUseCase(
            repository: communityDetailRepository
        )
        self.postCommentUseCase = PostCommentUseCase(
            repository: communityDetailRepository
        )
        self.reportPostUseCase = ReportPostUseCase(
            repository: communityDetailRepository
        )
        self.reportCommentUseCase = ReportCommentUseCase(
            repository: communityDetailRepository
        )
    }
}
