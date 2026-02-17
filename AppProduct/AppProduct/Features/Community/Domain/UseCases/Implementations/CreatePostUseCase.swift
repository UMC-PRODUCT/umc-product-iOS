//
//  CreatePostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

final class CreatePostUseCase: CreatePostUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityPostRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityPostRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(request: PostRequestDTO) async throws {
        // 유효성 검증
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "제목을 입력해주세요.")
        }
        
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "내용을 입력해주세요.")
        }
        
        try await repository.postPosts(request: request)
    }
}
