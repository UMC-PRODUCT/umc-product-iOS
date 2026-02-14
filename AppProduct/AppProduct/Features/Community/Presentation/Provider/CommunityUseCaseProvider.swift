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
}

/// Community UseCase Provider 구현
///
/// CommunityRepository를 직접 주입받아 UseCase들을 생성합니다.
final class CommunityUseCaseProvider: CommunityUseCaseProviding {
    // MARK: - Property

    let fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol
    let fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol
    let createPostUseCase: CreatePostUseCaseProtocol
    let createLightningUseCase: CreateLightningUseCaseProtocol
    let updatePostUseCase: UpdatePostUseCaseProtocol
    let updateLightningUseCase: UpdateLightningUseCaseProtocol
    let fetchCommentUseCase: FetchCommentsUseCaseProtocol

    // MARK: - Init

    init(
        communityRepository: CommunityRepositoryProtocol,
        communityPostRepository: CommunityPostRepositoryProtocol
    ) {
        self.fetchFameItemsUseCase = FetchFameItemsUseCase(
            repository: communityRepository
        )
        self.fetchCommunityItemsUseCase = FetchCommunityItemsUseCase(
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
            repository: communityRepository
        )
    }
}
