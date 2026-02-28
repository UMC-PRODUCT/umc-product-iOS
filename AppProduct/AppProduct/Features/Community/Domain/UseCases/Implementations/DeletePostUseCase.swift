//
//  DeletePostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 삭제 UseCase
final class DeletePostUseCase: DeletePostUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int) async throws {
        try await repository.deletePost(postId: postId)
    }
}
