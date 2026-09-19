//
//  ProjectStatistics.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 지원·매칭 통계 (`GET /statistics`, `GET /statistics/matchings`).
//  필드 이름은 서버 응답을 그대로 따른다. 인원 수는 서버 정수라 `String` 이다.
//

import Foundation
import UMCFoundation

// MARK: - 지원 통계 (`GET /statistics`)

/// 지부(또는 지정한 프로젝트들)의 지원 통계 (서버 `ChapterProjectStatisticsResponse`).
public struct ProjectChapterStatistics: Sendable, Equatable {
    /// `projectIds` 로 조회하면 `nil` 일 수 있다.
    public let chapterId: String?
    public let projects: [ProjectStatistics]
    public let summary: ProjectStatisticsSummary?

    public init(
        chapterId: String?,
        projects: [ProjectStatistics],
        summary: ProjectStatisticsSummary?
    ) {
        self.chapterId = chapterId
        self.projects = projects
        self.summary = summary
    }
}

/// 프로젝트 하나의 지원 통계 (서버 `ProjectStatisticsResponse`).
public struct ProjectStatistics: Sendable, Equatable {
    public let projectId: String
    public let projectMembers: [ProjectMemberStatistics]
    public let roundApplicationStatistics: [ProjectRoundApplicationStatistics]
    public let schoolApplicationStatistics: [ProjectRoundSchoolStatistics]

    public init(
        projectId: String,
        projectMembers: [ProjectMemberStatistics],
        roundApplicationStatistics: [ProjectRoundApplicationStatistics],
        schoolApplicationStatistics: [ProjectRoundSchoolStatistics]
    ) {
        self.projectId = projectId
        self.projectMembers = projectMembers
        self.roundApplicationStatistics = roundApplicationStatistics
        self.schoolApplicationStatistics = schoolApplicationStatistics
    }
}

/// 팀원별 지원 이력.
public struct ProjectMemberStatistics: Sendable, Equatable {
    public let projectMemberId: String
    public let memberId: String
    public let part: UMCPartType?
    public let status: ProjectMemberStatus
    public let applications: [ProjectMemberApplicationStatistics]

    public init(
        projectMemberId: String,
        memberId: String,
        part: UMCPartType?,
        status: ProjectMemberStatus,
        applications: [ProjectMemberApplicationStatistics]
    ) {
        self.projectMemberId = projectMemberId
        self.memberId = memberId
        self.part = part
        self.status = status
        self.applications = applications
    }
}

/// 팀원 한 명의 지원서 한 건.
public struct ProjectMemberApplicationStatistics: Sendable, Equatable {
    public let applicationId: String
    public let status: ProjectApplicationStatus
    public let matchingRound: ProjectMatchingRoundBrief?

    public init(
        applicationId: String,
        status: ProjectApplicationStatus,
        matchingRound: ProjectMatchingRoundBrief?
    ) {
        self.applicationId = applicationId
        self.status = status
        self.matchingRound = matchingRound
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

/// 차수별 학교 지원자 수 (프로젝트 통계의 `schoolApplicationStatistics`, 요약의 `roundSchoolRankings`).
public struct ProjectRoundSchoolStatistics: Sendable, Equatable {
    public let matchingRound: ProjectMatchingRoundBrief?
    public let schools: [ProjectSchoolApplicantCount]

    public init(
        matchingRound: ProjectMatchingRoundBrief?,
        schools: [ProjectSchoolApplicantCount]
    ) {
        self.matchingRound = matchingRound
        self.schools = schools
    }
}

/// 학교 하나의 지원자 수.
public struct ProjectSchoolApplicantCount: Sendable, Equatable {
    public let schoolId: String
    public let applicantCount: String

    public init(schoolId: String, applicantCount: String) {
        self.schoolId = schoolId
        self.applicantCount = applicantCount
    }
}

/// 지원 통계 요약 (서버 `ChapterProjectStatisticsSummaryResponse`).
public struct ProjectStatisticsSummary: Sendable, Equatable {
    public let roundApplicationStatistics: [ProjectRoundApplicationStatistics]
    public let roundSchoolRankings: [ProjectRoundSchoolStatistics]
    public let schoolMatchingStatistics: [ProjectSchoolMatchingStatistics]
    public let projectRoundStatistics: [ProjectRoundMemberStatistics]

    public init(
        roundApplicationStatistics: [ProjectRoundApplicationStatistics],
        roundSchoolRankings: [ProjectRoundSchoolStatistics],
        schoolMatchingStatistics: [ProjectSchoolMatchingStatistics],
        projectRoundStatistics: [ProjectRoundMemberStatistics]
    ) {
        self.roundApplicationStatistics = roundApplicationStatistics
        self.roundSchoolRankings = roundSchoolRankings
        self.schoolMatchingStatistics = schoolMatchingStatistics
        self.projectRoundStatistics = projectRoundStatistics
    }
}

/// 학교별 매칭 인원.
public struct ProjectSchoolMatchingStatistics: Sendable, Equatable {
    public let schoolId: String
    public let matchedMemberCount: String
    public let totalMemberCount: String
    /// 지원 통계 요약에만 온다. 매칭 통계에서는 `nil`.
    public let appliedMemberCount: String?

    public init(
        schoolId: String,
        matchedMemberCount: String,
        totalMemberCount: String,
        appliedMemberCount: String?
    ) {
        self.schoolId = schoolId
        self.matchedMemberCount = matchedMemberCount
        self.totalMemberCount = totalMemberCount
        self.appliedMemberCount = appliedMemberCount
    }
}

/// 프로젝트별 차수 인원.
public struct ProjectRoundMemberStatistics: Sendable, Equatable {
    public let projectId: String
    public let matchingRounds: [ProjectRoundMemberCount]

    public init(projectId: String, matchingRounds: [ProjectRoundMemberCount]) {
        self.projectId = projectId
        self.matchingRounds = matchingRounds
    }
}

/// 차수 하나의 지원·매칭 인원.
public struct ProjectRoundMemberCount: Sendable, Equatable {
    public let matchingRound: ProjectMatchingRoundBrief?
    public let appliedMemberCount: String
    public let matchedMemberCount: String

    public init(
        matchingRound: ProjectMatchingRoundBrief?,
        appliedMemberCount: String,
        matchedMemberCount: String
    ) {
        self.matchingRound = matchingRound
        self.appliedMemberCount = appliedMemberCount
        self.matchedMemberCount = matchedMemberCount
    }
}

// MARK: - 매칭 통계 (`GET /statistics/matchings`)

/// 지부의 매칭 통계 (서버 `ChapterProjectMatchingStatisticsResponse`).
public struct ProjectChapterMatchingStatistics: Sendable, Equatable {
    public let chapterId: String
    public let roundMatchingStatistics: [ProjectRoundMatchingStatistics]
    public let schoolMatchingStatistics: [ProjectSchoolMatchingStatistics]
    /// 차수 없이(랜덤 매칭 등) 합류한 인원.
    public let unclassifiedMatchingStatistics: ProjectUnclassifiedMatchingStatistics?

    public init(
        chapterId: String,
        roundMatchingStatistics: [ProjectRoundMatchingStatistics],
        schoolMatchingStatistics: [ProjectSchoolMatchingStatistics],
        unclassifiedMatchingStatistics: ProjectUnclassifiedMatchingStatistics?
    ) {
        self.chapterId = chapterId
        self.roundMatchingStatistics = roundMatchingStatistics
        self.schoolMatchingStatistics = schoolMatchingStatistics
        self.unclassifiedMatchingStatistics = unclassifiedMatchingStatistics
    }
}

/// 차수별 매칭 인원.
public struct ProjectRoundMatchingStatistics: Sendable, Equatable {
    public let matchingRound: ProjectMatchingRoundBrief?
    public let matchedMemberCount: String
    public let availableMemberCount: String
    public let projects: [ProjectMatchingCount]

    public init(
        matchingRound: ProjectMatchingRoundBrief?,
        matchedMemberCount: String,
        availableMemberCount: String,
        projects: [ProjectMatchingCount]
    ) {
        self.matchingRound = matchingRound
        self.matchedMemberCount = matchedMemberCount
        self.availableMemberCount = availableMemberCount
        self.projects = projects
    }
}

/// 프로젝트 하나의 매칭 인원.
public struct ProjectMatchingCount: Sendable, Equatable {
    public let projectId: String
    public let matchedMemberCount: String

    public init(projectId: String, matchedMemberCount: String) {
        self.projectId = projectId
        self.matchedMemberCount = matchedMemberCount
    }
}

/// 차수 미분류 매칭 인원.
public struct ProjectUnclassifiedMatchingStatistics: Sendable, Equatable {
    public let matchedMemberCount: String
    public let projects: [ProjectMatchingCount]

    public init(matchedMemberCount: String, projects: [ProjectMatchingCount]) {
        self.matchedMemberCount = matchedMemberCount
        self.projects = projects
    }
}
