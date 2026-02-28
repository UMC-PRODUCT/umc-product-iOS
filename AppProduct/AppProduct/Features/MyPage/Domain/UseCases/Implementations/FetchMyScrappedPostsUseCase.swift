//
//  FetchMyScrappedPostsUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

final class FetchMyScrappedPostsUseCase: FetchMyScrappedPostsUseCaseProtocol {
    private let repository: MyPageRepositoryProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        try await repository.fetchScrappedPosts(query: query)
    }
}
