//
//  ThreadMemberResponseDTO.swift
//  CommunityData
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation
import CommunityDomain
import UMCFoundation

/// `GET /threads/{threadId}/members`·`GET /threads/{threadId}/invitable` 의 원소.
///
/// 서버는 `profileImageUrl` 을 주지 않고, 초대 후보에는 `role` 도 없다. 둘 다 비면 폴백한다.
///
/// REST 는 ID 를 String 으로 주지만 STOMP 는 raw number 로 준다. 멤버 목록은 지금 REST 에서만
/// 쓰이더라도 `decodeFlexibleString*` 으로 받아 두면 나중에 이벤트 페이로드를 붙일 때 DTO 를
/// 두 벌 만들 필요가 없다.
public struct ThreadMemberDTO: Codable {

    // MARK: - Property

    public let memberId: String
    public let name: String
    public let part: String?
    public let profileImageUrl: String?
    public let role: String

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case memberId, name, part, profileImageUrl, role
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 식별자가 없는 원소는 강퇴·위임 대상으로 지목할 수 없다. throw 해서
        // `decodeLossyArray` 가 그 행만 버리게 둔다.
        self.memberId = try container.decodeFlexibleString(forKey: .memberId)
        self.name = container.decodeFlexibleStringOrEmpty(forKey: .name)
        self.part = container.decodeFlexibleStringOrNil(forKey: .part)
        self.profileImageUrl = container.decodeFlexibleStringOrNil(forKey: .profileImageUrl)
        self.role = container.decodeFlexibleStringOrEmpty(forKey: .role)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberId, forKey: .memberId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(part, forKey: .part)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(role, forKey: .role)
    }

    // MARK: - Computed Property

    public var toDomain: ThreadMember {
        ThreadMember(
            id: memberId,
            name: name,
            // 빈 문자열을 그대로 올리면 화면이 "이름 · " 처럼 꼬리만 남은 줄을 그린다.
            part: part.flatMap { $0.isEmpty ? nil : $0 },
            profileImageURL: profileImageUrl.flatMap { $0.isEmpty ? nil : $0 },
            // 서버가 역할을 늘려도 목록 전체가 죽지 않도록 일반 참여자로 폴백한다.
            role: ThreadMemberRole(rawValue: role) ?? .member
        )
    }
}

/// `GET /threads/{threadId}/members`·`GET /threads/{threadId}/invitable` 응답 한 페이지.
///
/// 서버가 `offset`/`limit` 으로 잘라 준다. `nextOffset` 은 다음 요청에 그대로 넣을 절대 오프셋이고,
/// 마지막 페이지면 `null` 이다. 서버가 정수를 String 으로 주므로 둘 다 String 으로 받는다.
public struct ThreadMemberListDTO: Codable {

    // MARK: - Property

    public let items: [ThreadMemberDTO]
    public let nextOffset: String?
    public let total: String

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case items, nextOffset, total
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.items = try container.decodeLossyArray(ThreadMemberDTO.self, forKey: .items)
        self.nextOffset = container.decodeFlexibleStringOrNil(forKey: .nextOffset)
        self.total = container.decodeFlexibleStringOrNil(forKey: .total) ?? "0"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(nextOffset, forKey: .nextOffset)
        try container.encode(total, forKey: .total)
    }

    // MARK: - Computed Property

    public var toDomain: [ThreadMember] {
        items.map(\.toDomain)
    }
}
