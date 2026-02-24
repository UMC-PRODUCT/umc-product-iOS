//
//  CommunitySchoolResponseDTO.swift
//  AppProduct
//
//  Created by Codex on 2/24/26.
//

import Foundation

/// 학교 목록 응답 DTO
struct CommunitySchoolListResponseDTO: Codable {
    let schools: [CommunitySchoolDTO]
}

/// 학교 정보 DTO
struct CommunitySchoolDTO: Codable {
    let schoolId: Int
    let schoolName: String

    private enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try container.decodeIntFlexible(forKey: .schoolId)
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
    }
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? decode(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }

        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int or String convertible to Int"
            )
        )
    }
}
