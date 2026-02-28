//
//  FetchCommentsUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

final class FetchCommentsUseCase: FetchCommentsUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityDetailRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityDetailRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(postId: Int) async throws -> [CommunityCommentModel] {
        try await repository.getComments(postId: postId)
    }
}
