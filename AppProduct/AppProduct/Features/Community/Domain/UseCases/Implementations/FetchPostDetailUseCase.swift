//
//  FetchPostDetailUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

/// 게시글 상세 조회 UseCase
final class FetchPostDetailUseCase: FetchPostDetailUseCaseProtocol {
    private let repository: CommunityDetailRepositoryProtocol

    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }

    func execute(postId: Int) async throws -> CommunityItemModel {
        try await repository.getPostDetail(postId: postId)
    }
}
