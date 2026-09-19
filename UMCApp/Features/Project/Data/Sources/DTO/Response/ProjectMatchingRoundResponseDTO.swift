//
//  ProjectMatchingRoundResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import UMCFoundation
import ProjectDomain

/// 매칭 차수 (서버 `ProjectMatchingRoundResponse`).
public struct ProjectMatchingRoundResponseDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let phase: String
    let chapterId: String
    let startsAt: String?
    let endsAt: String?
    let decisionDeadline: String?
    let autoDecisionExecutedAt: String?
    let autoDecisionExecutedMemberId: String?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, type, phase, chapterId, startsAt, endsAt, decisionDeadline
        case autoDecisionExecutedAt, autoDecisionExecutedMemberId, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decode(String.self, forKey: .type)
        phase = try container.decode(String.self, forKey: .phase)
        chapterId = try container.decodeFlexibleString(forKey: .chapterId)
        startsAt = try container.decodeIfPresent(String.self, forKey: .startsAt)
        endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt)
        decisionDeadline = try container.decodeIfPresent(String.self, forKey: .decisionDeadline)
        autoDecisionExecutedAt = try container.decodeIfPresent(
            String.self,
            forKey: .autoDecisionExecutedAt
        )
        autoDecisionExecutedMemberId = try container.decodeFlexibleStringIfPresent(
            forKey: .autoDecisionExecutedMemberId
        )
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(type, forKey: .type)
        try container.encode(phase, forKey: .phase)
        try container.encode(chapterId, forKey: .chapterId)
        try container.encodeIfPresent(startsAt, forKey: .startsAt)
        try container.encodeIfPresent(endsAt, forKey: .endsAt)
        try container.encodeIfPresent(decisionDeadline, forKey: .decisionDeadline)
        try container.encodeIfPresent(autoDecisionExecutedAt, forKey: .autoDecisionExecutedAt)
        try container.encodeIfPresent(
            autoDecisionExecutedMemberId,
            forKey: .autoDecisionExecutedMemberId
        )
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    public func toDomain() -> ProjectMatchingRound {
        let parse = ServerDateTimeConverter.parseUTCDateTime
        return ProjectMatchingRound(
            id: id,
            name: name,
            description: description,
            type: ProjectMatchingType(rawValue: type) ?? .unknown,
            phase: ProjectMatchingPhase(rawValue: phase) ?? .unknown,
            chapterId: chapterId,
            startsAt: startsAt.flatMap(parse),
            endsAt: endsAt.flatMap(parse),
            decisionDeadline: decisionDeadline.flatMap(parse),
            autoDecisionExecutedAt: autoDecisionExecutedAt.flatMap(parse),
            autoDecisionExecutedMemberId: autoDecisionExecutedMemberId,
            createdAt: createdAt.flatMap(parse),
            updatedAt: updatedAt.flatMap(parse)
        )
    }
}

/// 매칭 차수 생성 응답 (서버 `ProjectMatchingRoundCreateResponse`).
public struct ProjectMatchingRoundCreateResponseDTO: Codable {
    let matchingRoundId: String

    private enum CodingKeys: String, CodingKey {
        case matchingRoundId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchingRoundId = try container.decodeFlexibleString(forKey: .matchingRoundId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matchingRoundId, forKey: .matchingRoundId)
    }
}
