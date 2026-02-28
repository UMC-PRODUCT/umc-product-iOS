//
//  AuthorizationUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

/// 공용 리소스 권한 UseCase 구현체
final class AuthorizationUseCase: AuthorizationUseCaseProtocol {

    // MARK: - Property
    private let repository: AuthorizationRepositoryProtocol

    // MARK: - Initializer
    init(repository: AuthorizationRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function
    func getResourcePermission(
        resourceType: AuthorizationResourceType,
        resourceId: Int
    ) async throws -> ResourcePermission {
        try await repository.getResourcePermission(
            resourceType: resourceType,
            resourceId: resourceId
        )
    }
}

