//
//  ChallengerSearchOffsetDTO.swift
//  AppProduct
//
//  Created by Codex on 2/24/26.
//

import Foundation

/// 챌린저 오프셋 검색 결과 DTO
///
/// `GET /api/v1/challenger/search/offset`
struct ChallengerSearchOffsetResultDTO: Codable, Sendable {
    let page: ChallengerSearchOffsetPageDTO

    private enum CodingKeys: String, CodingKey {
        case page
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(ChallengerSearchOffsetPageDTO.self, forKey: .page)
            ?? ChallengerSearchOffsetPageDTO(
                content: [],
                page: 0,
                size: 0,
                totalElements: 0,
                totalPages: 0,
                hasNext: false,
                hasPrevious: false
            )
    }
}

struct ChallengerSearchOffsetPageDTO: Codable, Sendable {
    let content: [ChallengerSearchOffsetItemDTO]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool

    private enum CodingKeys: String, CodingKey {
        case content
        case page
        case size
        case totalElements
        case totalPages
        case hasNext
        case hasPrevious
    }

    init(
        content: [ChallengerSearchOffsetItemDTO],
        page: Int,
        size: Int,
        totalElements: Int,
        totalPages: Int,
        hasNext: Bool,
        hasPrevious: Bool
    ) {
        self.content = content
        self.page = page
        self.size = size
        self.totalElements = totalElements
        self.totalPages = totalPages
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([ChallengerSearchOffsetItemDTO].self, forKey: .content) ?? []
        page = try container.decodeIntFlexibleIfPresent(forKey: .page) ?? 0
        size = try container.decodeIntFlexibleIfPresent(forKey: .size) ?? 0
        totalElements = try container.decodeIntFlexibleIfPresent(forKey: .totalElements) ?? 0
        totalPages = try container.decodeIntFlexibleIfPresent(forKey: .totalPages) ?? 0
        hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
        hasPrevious = try container.decodeBoolFlexibleIfPresent(forKey: .hasPrevious) ?? false
    }
}

struct ChallengerSearchOffsetItemDTO: Codable, Sendable {
    let challengerId: Int
    let memberId: Int
    let gisuId: Int
    let generation: Int?
    let gisu: Int?
    let part: String
    let name: String
    let nickname: String
    let schoolName: String
    let pointSum: Double
    let profileImageLink: String?
    let roleTypes: [ManagementTeam]

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case memberId
        case gisuId
        case generation
        case gisu
        case part
        case name
        case nickname
        case schoolName
        case pointSum
        case profileImageLink
        case roleTypes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeIntFlexibleIfPresent(forKey: .challengerId) ?? 0
        memberId = try container.decodeIntFlexibleIfPresent(forKey: .memberId) ?? 0
        gisuId = try container.decodeIntFlexibleIfPresent(forKey: .gisuId) ?? 0
        generation = try container.decodeIntFlexibleIfPresent(forKey: .generation)
        gisu = try container.decodeIntFlexibleIfPresent(forKey: .gisu)
        part = try container.decodeIfPresent(String.self, forKey: .part) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        pointSum = try container.decodeDoubleFlexibleIfPresent(forKey: .pointSum) ?? 0
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)

        let rawRoleTypes = try container.decodeIfPresent([String].self, forKey: .roleTypes) ?? []
        roleTypes = rawRoleTypes.compactMap(ManagementTeam.init(rawValue:))
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
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return Int(doubleValue)
        }

        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }

    func decodeDoubleFlexibleIfPresent(forKey key: Key) throws -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key),
           let parsed = Double(value) {
            return parsed
        }
        return nil
    }

    func decodeBoolFlexibleIfPresent(forKey key: Key) throws -> Bool? {
        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue != 0
        }
        if let stringValue = try? decode(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }
}
