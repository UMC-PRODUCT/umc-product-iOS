//
//  CommunityUseCaseProvider.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

/// Community Feature에서 사용하는 UseCase들을 제공하는 Provider Protocol
protocol CommunityUseCaseProviding {
    var fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol { get }
    var fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol { get }
    var createPostUseCase: CreatePostUseCaseProtocol { get }
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
    let fetchCommentUseCase: FetchCommentsUseCaseProtocol

    // MARK: - Init

    init(communityRepository: CommunityRepositoryProtocol) {
        self.fetchFameItemsUseCase = FetchFameItemsUseCase(
            repository: communityRepository
        )
        self.fetchCommunityItemsUseCase = FetchCommunityItemsUseCase(
            repository: communityRepository
        )
        self.createPostUseCase = CreatePostUseCase(
            repository: communityRepository
        )
        self.fetchCommentUseCase = FetchCommentsUseCase(
            repository: communityRepository
        )
    }
}
