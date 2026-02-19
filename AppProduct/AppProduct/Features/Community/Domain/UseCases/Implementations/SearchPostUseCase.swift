//
//  SearchPostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/18/26.
//

import Foundation

final class SearchPostUseCase: SearchPostUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(query: PostSearchQuery) async throws -> (items: [CommunityItemModel], hasNext: Bool) {
        try await repository.getSearch(query: query)
    }
}
