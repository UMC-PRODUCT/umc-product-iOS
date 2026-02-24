//
//  MemberManagementProfileDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 멤버 프로필 응답 DTO (멤버 관리 화면용)
///
/// `GET /api/v1/member/profile/{memberId}`
struct MemberManagementProfileDTO: Codable, Sendable {
    let id: Int
    let name: String
    let nickname: String
    let schoolName: String
    let profileImageLink: String?
    let roles: [MemberManagementRoleDTO]
    let challengerRecords: [MemberManagementChallengerRecordDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case schoolName
        case profileImageLink
        case roles
        case challengerRecords
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntFlexibleIfPresent(forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        roles = try container.decodeIfPresent(
            [MemberManagementRoleDTO].self,
            forKey: .roles
        ) ?? []
        challengerRecords = try container.decodeIfPresent(
            [MemberManagementChallengerRecordDTO].self,
            forKey: .challengerRecords
        ) ?? []
    }
}

struct MemberManagementRoleDTO: Codable, Sendable {
    let challengerId: Int?
    let roleType: ManagementTeam

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case roleType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeIntFlexibleIfPresent(
            forKey: .challengerId
        )
        roleType = try container.decodeIfPresent(
            ManagementTeam.self,
            forKey: .roleType
        ) ?? .challenger
    }
}

struct MemberManagementChallengerRecordDTO: Codable, Sendable {
    let challengerId: Int
    let memberId: Int
    let gisu: Int
    let gisuId: Int
    let part: String
    let challengerPoints: [MemberManagementPointDTO]
    let fallbackPoints: [MemberManagementPointDTO]

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case memberId
        case gisu
        case gisuId
        case part
        case challengerPoints
        case fallbackPoints = "points"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeIntFlexibleIfPresent(forKey: .challengerId) ?? 0
        memberId = try container.decodeIntFlexibleIfPresent(forKey: .memberId) ?? 0
        gisu = try container.decodeIntFlexibleIfPresent(forKey: .gisu) ?? 0
        gisuId = try container.decodeIntFlexibleIfPresent(forKey: .gisuId) ?? 0
        part = try container.decodeIfPresent(String.self, forKey: .part) ?? ""
        challengerPoints = try container.decodeIfPresent(
            [MemberManagementPointDTO].self,
            forKey: .challengerPoints
        ) ?? []
        fallbackPoints = try container.decodeIfPresent(
            [MemberManagementPointDTO].self,
            forKey: .fallbackPoints
        ) ?? []
    }

    var resolvedPoints: [MemberManagementPointDTO] {
        challengerPoints.isEmpty ? fallbackPoints : challengerPoints
    }
}

struct MemberManagementPointDTO: Codable, Sendable {
    let id: Int
    let pointType: String
    let point: Double
    let description: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case pointType
        case point
        case description
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntFlexibleIfPresent(forKey: .id) ?? 0
        pointType = try container.decodeIfPresent(String.self, forKey: .pointType) ?? ""
        point = try container.decodeDoubleFlexibleIfPresent(forKey: .point) ?? 0
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
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
}
