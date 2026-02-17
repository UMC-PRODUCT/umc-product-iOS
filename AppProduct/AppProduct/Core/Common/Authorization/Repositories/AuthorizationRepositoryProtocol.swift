//
//  AuthorizationRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

/// 공용 리소스 권한 Repository 인터페이스
protocol AuthorizationRepositoryProtocol {
    /// 특정 리소스에 대한 현재 사용자 권한을 조회합니다.
    func getResourcePermission(
        resourceType: AuthorizationResourceType,
        resourceId: Int
    ) async throws -> ResourcePermission
}

