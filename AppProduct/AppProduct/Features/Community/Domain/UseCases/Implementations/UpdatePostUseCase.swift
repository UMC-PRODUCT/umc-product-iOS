//
//  UpdatePostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

final class UpdatePostUseCase: UpdatePostUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityPostRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityPostRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(postId: Int, request: PostRequestDTO) async throws {
        // 유효성 검증
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "제목을 입력해주세요.")
        }
        
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "내용을 입력해주세요.")
        }
        
        try await repository.patchPosts(postId: postId, request: request)
    }
}
