//
//  ProjectMatchingRound.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 매칭 차수 (서버 `ProjectMatchingRoundResponse`).
///
/// 서버 시각은 UTC ISO 8601 이다. 해석에 실패한 시각은 `nil`.
public struct ProjectMatchingRound: Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let type: ProjectMatchingType
    public let phase: ProjectMatchingPhase
    public let chapterId: String
    public let startsAt: Date?
    public let endsAt: Date?
    public let decisionDeadline: Date?
    /// 자동 결정이 아직 돌지 않았으면 `nil`.
    public let autoDecisionExecutedAt: Date?
    public let autoDecisionExecutedMemberId: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String,
        name: String,
        description: String?,
        type: ProjectMatchingType,
        phase: ProjectMatchingPhase,
        chapterId: String,
        startsAt: Date?,
        endsAt: Date?,
        decisionDeadline: Date?,
        autoDecisionExecutedAt: Date?,
        autoDecisionExecutedMemberId: String?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.phase = phase
        self.chapterId = chapterId
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.decisionDeadline = decisionDeadline
        self.autoDecisionExecutedAt = autoDecisionExecutedAt
        self.autoDecisionExecutedMemberId = autoDecisionExecutedMemberId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 매칭 차수 생성 입력 (`POST /api/v1/project/matching-rounds`).
public struct ProjectMatchingRoundDraft: Sendable, Equatable {
    /// 공백 불가, 255자 이하.
    public let name: String
    public let description: String?
    public let type: ProjectMatchingType
    /// `.randomMatching` 은 보낼 수 없다.
    public let phase: ProjectMatchingPhase
    public let chapterId: String
    public let startsAt: Date
    public let endsAt: Date
    public let decisionDeadline: Date

    public init(
        name: String,
        description: String?,
        type: ProjectMatchingType,
        phase: ProjectMatchingPhase,
        chapterId: String,
        startsAt: Date,
        endsAt: Date,
        decisionDeadline: Date
    ) {
        self.name = name
        self.description = description
        self.type = type
        self.phase = phase
        self.chapterId = chapterId
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.decisionDeadline = decisionDeadline
    }
}

/// 매칭 차수 수정 입력 (`PATCH /api/v1/project/matching-rounds/{id}`).
///
/// `nil` 인 필드는 요청에서 빠져 서버 값을 그대로 둔다. 지부(`chapterId`)는 바꿀 수 없다.
public struct ProjectMatchingRoundUpdate: Sendable, Equatable {
    public let name: String?
    public let description: String?
    public let type: ProjectMatchingType?
    public let phase: ProjectMatchingPhase?
    public let startsAt: Date?
    public let endsAt: Date?
    public let decisionDeadline: Date?

    public init(
        name: String? = nil,
        description: String? = nil,
        type: ProjectMatchingType? = nil,
        phase: ProjectMatchingPhase? = nil,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        decisionDeadline: Date? = nil
    ) {
        self.name = name
        self.description = description
        self.type = type
        self.phase = phase
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.decisionDeadline = decisionDeadline
    }
}
