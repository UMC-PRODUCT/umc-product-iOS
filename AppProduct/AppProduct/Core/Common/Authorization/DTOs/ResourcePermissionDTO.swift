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
    let resourceId: String
    let permissions: [ResourcePermissionItemDTO]

    private enum CodingKeys: String, CodingKey {
        case resourceType
        case resourceId
        case permissions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resourceType = try container.decode(String.self, forKey: .resourceType)
        permissions = try container.decodeIfPresent([ResourcePermissionItemDTO].self, forKey: .permissions) ?? []
        resourceId = try container.decodeIntFlexible(forKey: .resourceId)
    }
}

/// 단일 권한 항목 DTO
struct ResourcePermissionItemDTO: Codable {
    let permissionType: String
    let hasPermission: Bool
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }
}
