//
//  PostLikeUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 좋아요 UseCase
final class PostLikeUseCase: PostLikeUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int) async throws {
        try await repository.postLike(postId: postId)
    }
}
