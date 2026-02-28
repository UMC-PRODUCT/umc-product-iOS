//
//  DeleteCommentUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 댓글 삭제 UseCase
final class DeleteCommentUseCase: DeleteCommentUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int, commentId: Int) async throws {
        try await repository.deleteComment(postId: postId, commentId: commentId)
    }
}
