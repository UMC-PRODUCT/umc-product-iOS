//
//  MemberBlockRepository.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/29/26.
//

import CoreDomain
import Foundation
import Moya
import UMCFoundation

/// 서버 PR #1439의 회원 차단 계약. 미배포 환경 오류는 성공으로 치환하지 않는다.
public enum MemberBlockRouter: BaseTargetType {
    case list
    case block(String)
    case unblock(String)

    public var path: String {
        switch self {
        case .list: "/api/v1/member/blocks"
        case .block(let memberId), .unblock(let memberId): "/api/v1/member/blocks/\(memberId)"
        }
    }
    public var method: Moya.Method {
        switch self {
        case .list: .get
        case .block: .post
        case .unblock: .delete
        }
    }
    public var task: Moya.Task { .requestPlain }
}

public final class MemberBlockRepository: MemberBlockRepositoryProtocol, @unchecked Sendable {
    private let adapter: MoyaNetworkAdapter

    public init(adapter: MoyaNetworkAdapter) { self.adapter = adapter }

    public func fetchBlockedMemberIds() async throws -> Set<String> {
        let response = try await adapter.request(MemberBlockRouter.list)
        let result = try JSONDecoder().decode(APIResponse<BlockedMemberListDTO>.self, from: response.data)
        return Set(try result.unwrap().members.map(\.memberId))
    }

    public func setBlocked(_ blocked: Bool, memberId: String) async throws -> Bool {
        let route: MemberBlockRouter = blocked ? .block(memberId) : .unblock(memberId)
        let response = try await adapter.request(route)
        let result = try JSONDecoder().decode(APIResponse<MemberBlockResultDTO>.self, from: response.data)
        return try result.unwrap().isBlocked
    }
}

struct MemberBlockResultDTO: Codable {
    let memberId: String
    let isBlocked: Bool
    enum CodingKeys: String, CodingKey { case memberId, isBlocked }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        isBlocked = try values.decode(Bool.self, forKey: .isBlocked)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(isBlocked, forKey: .isBlocked)
    }
}

struct BlockedMemberListDTO: Codable {
    let members: [BlockedMemberDTO]
    enum CodingKeys: String, CodingKey { case members }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // 차단 목록은 lossy 디코딩하지 않는다. 누락 시 숨겨야 할 메시지가 노출된다.
        members = try values.decode([BlockedMemberDTO].self, forKey: .members)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(members, forKey: .members)
    }
}

struct BlockedMemberDTO: Codable {
    let memberId: String
    enum CodingKeys: String, CodingKey { case memberId }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
    }
}
