//
//  UpdateLightningUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/15/26.
//

import Foundation

final class UpdateLightningUseCase: UpdateLightningUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityPostRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityPostRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(postId: Int, request: CreateLightningPostRequestDTO) async throws {
        // 유효성 검증
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "제목을 입력해주세요.")
        }
        
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "내용을 입력해주세요.")
        }
        
        // 번개 카테고리 유효성 검증
        guard !request.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "장소를 선택해주세요.")
        }

        guard !request.openChatUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "오픈채팅 링크를 입력해주세요.")
        }
        
        try await repository.patchLightning(postId: postId, request: request)
    }
}
