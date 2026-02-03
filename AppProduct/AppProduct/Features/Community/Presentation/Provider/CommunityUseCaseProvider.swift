//
//  CommunityUseCaseProvider.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

protocol CommunityUseCaseProviding {
    var fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol { get }
    var fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol { get }
    var createPostUseCase: CreatePostUseCaseProtocol { get }
}

final class CommunityUseCaseProvider: CommunityUseCaseProviding {
    // MARK: - Property
    
    let fetchFameItemsUseCase: FetchFameItemsUseCaseProtocol
    let fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol
    let createPostUseCase: CreatePostUseCaseProtocol
    
    // MARK: - Init
    
    init(
        repositoryProvider: CommunityRepositoryProviding
    ) {
        self.fetchFameItemsUseCase = FetchFameItemsUseCase(repository: repositoryProvider.communityRepository)
        self.fetchCommunityItemsUseCase = FetchCommunityItemsUseCase(repository: repositoryProvider.communityRepository)
        self.createPostUseCase = CreatePostUseCase(repository: repositoryProvider.communityRepository)
    }
}
