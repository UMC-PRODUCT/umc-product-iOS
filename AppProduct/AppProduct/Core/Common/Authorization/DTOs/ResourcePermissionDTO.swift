//
//  ResourcePermissionDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation

/// 리소스 권한 조회 응답 DTO
struct ResourcePermissionResponseDTO: Codable {
    let resourceType: String
    let resourceId: Int
    let permissions: [ResourcePermissionItemDTO]
}

/// 단일 권한 항목 DTO
struct ResourcePermissionItemDTO: Codable {
    let permissionType: String
    let hasPermission: Bool
}

