//
//  AuthorizationRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation
import Moya

/// 공용 리소스 권한 Repository 구현체
struct AuthorizationRepository: AuthorizationRepositoryProtocol {

    // MARK: - Property
    private let adapter: MoyaNetworkAdapter

    // MARK: - Initializer
    init(adapter: MoyaNetworkAdapter) {
        self.adapter = adapter
    }

    // MARK: - Function
    func getResourcePermission(
        resourceType: AuthorizationResourceType,
        resourceId: Int
    ) async throws -> ResourcePermission {
        let response = try await adapter.request(
            AuthorizationRouter.getResourcePermission(
                resourceType: resourceType,
                resourceId: resourceId
            )
        )

        let apiResponse = try JSONDecoder().decode(
            APIResponse<ResourcePermissionResponseDTO>.self,
            from: response.data
        )
        let dto = try apiResponse.unwrap()
        guard let mappedResourceType = AuthorizationResourceType(rawValue: dto.resourceType) else {
            throw RepositoryError.decodingError(detail: "Unknown resourceType: \(dto.resourceType)")
        }

        let granted = Set(
            dto.permissions.compactMap { item -> AuthorizationPermissionType? in
                guard item.hasPermission else { return nil }
                return AuthorizationPermissionType(rawValue: item.permissionType)
            }
        )

        return ResourcePermission(
            resourceType: mappedResourceType,
            resourceId: dto.resourceId,
            grantedPermissions: granted
        )
    }
}
