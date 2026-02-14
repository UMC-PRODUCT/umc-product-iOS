//
//  CreatePostUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

final class CreatePostUseCase: CreatePostUseCaseProtocol {
    // MARK: - Property
    
    private let repository: CommunityRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: CommunityRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    
    func execute(request: PostRequestDTO) async throws -> CommunityItemModel {
        // 유효성 검증
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "제목을 입력해주세요.")
        }
        
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.custom(message: "내용을 입력해주세요.")
        }
        
//        // 번개 카테고리 유효성 검증
//        if request.category == .impromptu {
//            guard let place = request.place, !place.name.isEmpty else {
//                throw DomainError.custom(message: "장소를 선택해주세요.")
//            }
//            
//            guard let link = request.link, !link.isEmpty else {
//                throw DomainError.custom(message: "오픈채팅 링크를 입력해주세요.")
//            }
//        }
        
//        return try await repository.createPost(request: request)
        
        return .init(userId: 1, category: .free, title: "", content: "", profileImage: nil, userName: "", part: .design, createdAt: Date(), likeCount: 0, commentCount: 0, scrapCount: 0)
    }
}
