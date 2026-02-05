//
//  FetchMembersUseCase.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

/// 멤버 목록 조회 UseCase 구현체
final class FetchMembersUseCase: FetchMembersUseCaseProtocol {
    // MARK: - Property
    private let repository: MemberRepositoryProtocol
    
    // MARK: - Init
    init(repository: MemberRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Function
    func execute() async throws -> [MemberManagementItem] {
        try await repository.fetchMembers()
    }
}
