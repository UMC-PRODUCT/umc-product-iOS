//
//  ProjectStatistics.swift
//  ProjectDomain
//
//  Created by euijjang97 on 11/1/26.
//

import Foundation
import UMCFoundation

/// 프로젝트 지원 통계.
public struct ProjectChapterStatistics: Sendable, Equatable {
    public let chapterId: String
    public let matchingRound: ProjectMatchingRoundBrief?
    public let summary: ProjectStatisticsSummary

    public init(
        chapterId: String,
        matchingRound: ProjectMatchingRoundBrief?,
        summary: ProjectStatisticsSummary
    ) {
        self.chapterId = chapterId
        self.matchingRound = matchingRound
        self.summary = summary
    }
}

/// 차수·학교·프로젝트별 지원 현황.
public struct ProjectStatisticsSummary: Sendable, Equatable {
    public let roundApplicationStatistics: [ProjectRoundApplicationStatistics]
    public let schoolApplicationStatistics: [ProjectSchoolApplicationStatistics]
    public let projectRoundStatistics: [ProjectApplicationProjectStatistics]

    public init(
        roundApplicationStatistics: [ProjectRoundApplicationStatistics],
        schoolApplicationStatistics: [ProjectSchoolApplicationStatistics],
        projectRoundStatistics: [ProjectApplicationProjectStatistics]
    ) {
        self.roundApplicationStatistics = roundApplicationStatistics
        self.schoolApplicationStatistics = schoolApplicationStatistics
        self.projectRoundStatistics = projectRoundStatistics
    }
}

/// 차수별 지원 인원.
public struct ProjectRoundApplicationStatistics: Sendable, Equatable {
    public let matchingRound: ProjectMatchingRoundBrief?
    public let appliedMemberCount: String
    public let availableMemberCount: String

    public init(
        matchingRound: ProjectMatchingRoundBrief?,
        appliedMemberCount: String,
        availableMemberCount: String
    ) {
        self.matchingRound = matchingRound
        self.appliedMemberCount = appliedMemberCount
        self.availableMemberCount = availableMemberCount
    }
}

/// 학교별 지원 가능 총원과 차수별 지원 인원.
public struct ProjectSchoolApplicationStatistics: Sendable, Equatable {
    public let schoolId: String
    public let schoolName: String
    public let totalMemberCount: String
    public let rounds: [ProjectApplicationPhaseCount]

    public init(
        schoolId: String,
        schoolName: String,
        totalMemberCount: String,
        rounds: [ProjectApplicationPhaseCount]
    ) {
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.totalMemberCount = totalMemberCount
        self.rounds = rounds
    }
}

/// 프로젝트별 차수별 지원 인원.
public struct ProjectApplicationProjectStatistics: Sendable, Equatable {
    public let projectId: String
    public let projectName: String
    public let rounds: [ProjectApplicationPhaseCount]

    public init(
        projectId: String,
        projectName: String,
        rounds: [ProjectApplicationPhaseCount]
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.rounds = rounds
    }
}

/// 차수별 지원 인원.
public struct ProjectApplicationPhaseCount: Sendable, Equatable {
    public let phase: ProjectMatchingPhase
    public let applicantCount: String

    public init(
        phase: ProjectMatchingPhase,
        applicantCount: String
    ) {
        self.phase = phase
        self.applicantCount = applicantCount
    }
}

/// 공개된 매칭 결과 집계.
public struct ProjectChapterMatchingStatistics: Sendable, Equatable {
    public let chapterId: String
    public let roundMatchingStatistics: [ProjectRoundMatchingStatistics]
    public let schoolMatchingStatistics: [ProjectSchoolMatchingStatistics]
    public let projectMatchingStatistics: [ProjectMatchingProjectStatistics]

    public init(
        chapterId: String,
        roundMatchingStatistics: [ProjectRoundMatchingStatistics],
        schoolMatchingStatistics: [ProjectSchoolMatchingStatistics],
        projectMatchingStatistics: [ProjectMatchingProjectStatistics]
    ) {
        self.chapterId = chapterId
        self.roundMatchingStatistics = roundMatchingStatistics
        self.schoolMatchingStatistics = schoolMatchingStatistics
        self.projectMatchingStatistics = projectMatchingStatistics
    }
}

/// 차수별 매칭 인원. 랜덤 매칭도 phase로 구분한다.
public struct ProjectRoundMatchingStatistics: Sendable, Equatable {
    public let phase: ProjectMatchingPhase
    public let matchedMemberCount: String
    public let availableMemberCount: String

    public init(
        phase: ProjectMatchingPhase,
        matchedMemberCount: String,
        availableMemberCount: String
    ) {
        self.phase = phase
        self.matchedMemberCount = matchedMemberCount
        self.availableMemberCount = availableMemberCount
    }
}

/// 학교별 누적 매칭 인원과 대상 총원.
public struct ProjectSchoolMatchingStatistics: Sendable, Equatable {
    public let schoolId: String
    public let schoolName: String
    public let matchedMemberCount: String
    public let totalMemberCount: String

    public init(
        schoolId: String,
        schoolName: String,
        matchedMemberCount: String,
        totalMemberCount: String
    ) {
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.matchedMemberCount = matchedMemberCount
        self.totalMemberCount = totalMemberCount
    }
}

/// 프로젝트별 누적 매칭 인원 및 정원.
public struct ProjectMatchingProjectStatistics: Sendable, Equatable {
    public let projectId: String
    public let projectName: String
    public let matchedMemberCount: String
    public let quota: String
    public let rounds: [ProjectMatchingPhaseCount]
    public let parts: [ProjectMatchingPartStatistics]

    public init(
        projectId: String,
        projectName: String,
        matchedMemberCount: String,
        quota: String,
        rounds: [ProjectMatchingPhaseCount],
        parts: [ProjectMatchingPartStatistics]
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.matchedMemberCount = matchedMemberCount
        self.quota = quota
        self.rounds = rounds
        self.parts = parts
    }
}

/// 차수별 매칭 완료 인원.
public struct ProjectMatchingPhaseCount: Sendable, Equatable {
    public let phase: ProjectMatchingPhase
    public let matchedMemberCount: String

    public init(
        phase: ProjectMatchingPhase,
        matchedMemberCount: String
    ) {
        self.phase = phase
        self.matchedMemberCount = matchedMemberCount
    }
}

/// 파트별 매칭 완료 인원과 정원.
public struct ProjectMatchingPartStatistics: Sendable, Equatable {
    public let part: UMCPartType?
    public let matchedMemberCount: String
    public let quota: String

    public init(
        part: UMCPartType?,
        matchedMemberCount: String,
        quota: String
    ) {
        self.part = part
        self.matchedMemberCount = matchedMemberCount
        self.quota = quota
    }
}
