//
//  FetchMyPostsUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class FetchMyPostsUseCase: FetchMyPostsUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        try await repository.fetchMyPosts(query: query)
    }
}
