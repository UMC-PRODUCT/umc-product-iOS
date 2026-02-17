//
//  PostCommentUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 댓글 작성 UseCase
final class PostCommentUseCase: PostCommentUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int, request: PostCommentRequest) async throws {
        try await repository.postComment(postId: postId, request: request)
    }
}
