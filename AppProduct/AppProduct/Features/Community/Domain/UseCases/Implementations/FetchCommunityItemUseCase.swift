//
//  FetchCommunityItemsUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

final class FetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(query: PostListQuery) async throws -> (items: [CommunityItemModel], hasNext: Bool) {
        try await repository.getPosts(query: query)
    }
}
