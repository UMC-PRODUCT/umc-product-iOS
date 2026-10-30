//
//  MemberBlockResponseDTO.swift
//  CommunityData
//
//  Created by euijjang97 on 10/30/26.
//

import Foundation
import UMCFoundation

struct BlockedMemberDTO: Codable {
    let memberId: String

    enum CodingKeys: String, CodingKey { case memberId }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decodeFlexibleString(forKey: .memberId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberId, forKey: .memberId)
    }
}

struct BlockedMemberListDTO: Codable {
    let members: [BlockedMemberDTO]

    enum CodingKeys: String, CodingKey { case members }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 손상된 차단 목록을 부분 성공으로 취급하면 누락된 회원의 원문이 노출된다.
        members = try container.decode([BlockedMemberDTO].self, forKey: .members)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(members, forKey: .members)
    }
}

struct MemberBlockResultDTO: Codable {
    let isBlocked: Bool

    enum CodingKeys: String, CodingKey { case isBlocked }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isBlocked = try container.decode(Bool.self, forKey: .isBlocked)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isBlocked, forKey: .isBlocked)
    }
}
