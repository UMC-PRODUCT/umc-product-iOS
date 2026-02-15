//
//  PostScrapUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 스크랩 UseCase
final class PostScrapUseCase: PostScrapUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int) async throws {
        try await repository.postScrap(postId: postId)
    }
}
