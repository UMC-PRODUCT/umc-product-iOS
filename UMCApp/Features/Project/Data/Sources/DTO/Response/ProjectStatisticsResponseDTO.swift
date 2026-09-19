//
//  ProjectStatisticsResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//
//  `GET /statistics`, `GET /statistics/matchings` 응답 DTO. 차수 정보는 `matchingRoundId`
//  키로 오며 ``ProjectMatchingRoundBriefDTO`` 가 받는다.
//

import Foundation
import UMCFoundation
import ProjectDomain

// MARK: - 지원 통계

/// 서버 `ChapterProjectStatisticsResponse`.
public struct ProjectChapterStatisticsResponseDTO: Codable {
    let chapterId: String?
    let projects: [ProjectStatisticsDTO]
    let summary: SummaryDTO?

    private enum CodingKeys: String, CodingKey {
        case chapterId, projects, summary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decodeFlexibleStringIfPresent(forKey: .chapterId)
        projects = try container.decodeIfPresent(
            [ProjectStatisticsDTO].self,
            forKey: .projects
        ) ?? []
        summary = try container.decodeIfPresent(SummaryDTO.self, forKey: .summary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(chapterId, forKey: .chapterId)
        try container.encode(projects, forKey: .projects)
        try container.encodeIfPresent(summary, forKey: .summary)
    }

    public func toDomain() -> ProjectChapterStatistics {
        ProjectChapterStatistics(
            chapterId: chapterId,
            projects: projects.map { $0.toDomain() },
            summary: summary?.toDomain()
        )
    }

    /// 서버 `ChapterProjectStatisticsSummaryResponse`.
    public struct SummaryDTO: Codable {
        let roundApplicationStatistics: [ProjectRoundApplicationStatisticsDTO]
        let roundSchoolRankings: [ProjectRoundSchoolStatisticsDTO]
        let schoolMatchingStatistics: [ProjectSchoolMatchingStatisticsDTO]
        let projectRoundStatistics: [ProjectRoundMemberStatisticsDTO]

        private enum CodingKeys: String, CodingKey {
            case roundApplicationStatistics, roundSchoolRankings
            case schoolMatchingStatistics, projectRoundStatistics
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            roundApplicationStatistics = try container.decodeIfPresent(
                [ProjectRoundApplicationStatisticsDTO].self,
                forKey: .roundApplicationStatistics
            ) ?? []
            roundSchoolRankings = try container.decodeIfPresent(
                [ProjectRoundSchoolStatisticsDTO].self,
                forKey: .roundSchoolRankings
            ) ?? []
            schoolMatchingStatistics = try container.decodeIfPresent(
                [ProjectSchoolMatchingStatisticsDTO].self,
                forKey: .schoolMatchingStatistics
            ) ?? []
            projectRoundStatistics = try container.decodeIfPresent(
                [ProjectRoundMemberStatisticsDTO].self,
                forKey: .projectRoundStatistics
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(roundApplicationStatistics, forKey: .roundApplicationStatistics)
            try container.encode(roundSchoolRankings, forKey: .roundSchoolRankings)
            try container.encode(schoolMatchingStatistics, forKey: .schoolMatchingStatistics)
            try container.encode(projectRoundStatistics, forKey: .projectRoundStatistics)
        }

        func toDomain() -> ProjectStatisticsSummary {
            ProjectStatisticsSummary(
                roundApplicationStatistics: roundApplicationStatistics.map { $0.toDomain() },
                roundSchoolRankings: roundSchoolRankings.map { $0.toDomain() },
                schoolMatchingStatistics: schoolMatchingStatistics.map { $0.toDomain() },
                projectRoundStatistics: projectRoundStatistics.map { $0.toDomain() }
            )
        }
    }
}

/// 서버 `ProjectStatisticsResponse`.
public struct ProjectStatisticsDTO: Codable {
    let projectId: String
    let projectMembers: [MemberDTO]
    let roundApplicationStatistics: [ProjectRoundApplicationStatisticsDTO]
    let schoolApplicationStatistics: [ProjectRoundSchoolStatisticsDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId, projectMembers, roundApplicationStatistics, schoolApplicationStatistics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        projectMembers = try container.decodeIfPresent(
            [MemberDTO].self,
            forKey: .projectMembers
        ) ?? []
        roundApplicationStatistics = try container.decodeIfPresent(
            [ProjectRoundApplicationStatisticsDTO].self,
            forKey: .roundApplicationStatistics
        ) ?? []
        schoolApplicationStatistics = try container.decodeIfPresent(
            [ProjectRoundSchoolStatisticsDTO].self,
            forKey: .schoolApplicationStatistics
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(projectMembers, forKey: .projectMembers)
        try container.encode(roundApplicationStatistics, forKey: .roundApplicationStatistics)
        try container.encode(schoolApplicationStatistics, forKey: .schoolApplicationStatistics)
    }

    func toDomain() -> ProjectStatistics {
        ProjectStatistics(
            projectId: projectId,
            projectMembers: projectMembers.map { $0.toDomain() },
            roundApplicationStatistics: roundApplicationStatistics.map { $0.toDomain() },
            schoolApplicationStatistics: schoolApplicationStatistics.map { $0.toDomain() }
        )
    }

    /// 팀원별 지원 이력. 강제 배정된 팀원은 `applications` 가 비어 있다.
    public struct MemberDTO: Codable {
        let projectMemberId: String
        let memberId: String
        let part: String?
        let status: String?
        let applications: [ApplicationDTO]

        private enum CodingKeys: String, CodingKey {
            case projectMemberId, memberId, part, status, applications
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            projectMemberId = try container.decodeFlexibleString(forKey: .projectMemberId)
            memberId = try container.decodeFlexibleString(forKey: .memberId)
            part = try container.decodeIfPresent(String.self, forKey: .part)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            applications = try container.decodeIfPresent(
                [ApplicationDTO].self,
                forKey: .applications
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(projectMemberId, forKey: .projectMemberId)
            try container.encode(memberId, forKey: .memberId)
            try container.encodeIfPresent(part, forKey: .part)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encode(applications, forKey: .applications)
        }

        func toDomain() -> ProjectMemberStatistics {
            ProjectMemberStatistics(
                projectMemberId: projectMemberId,
                memberId: memberId,
                part: part.flatMap(UMCPartType.init(apiValue:)),
                status: status.flatMap(ProjectMemberStatus.init(rawValue:)) ?? .unknown,
                applications: applications.map { $0.toDomain() }
            )
        }
    }

    /// 팀원 한 명의 지원서 한 건.
    public struct ApplicationDTO: Codable {
        let applicationId: String
        let status: String?
        let matchingRound: ProjectMatchingRoundBriefDTO?

        private enum CodingKeys: String, CodingKey {
            case applicationId, status, matchingRound
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            applicationId = try container.decodeFlexibleString(forKey: .applicationId)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            matchingRound = try container.decodeIfPresent(
                ProjectMatchingRoundBriefDTO.self,
                forKey: .matchingRound
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(applicationId, forKey: .applicationId)
            try container.encodeIfPresent(status, forKey: .status)
            try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        }

        func toDomain() -> ProjectMemberApplicationStatistics {
            ProjectMemberApplicationStatistics(
                applicationId: applicationId,
                status: status.flatMap(ProjectApplicationStatus.init(rawValue:)) ?? .unknown,
                matchingRound: matchingRound?.toDomain()
            )
        }
    }
}

/// 차수별 지원 인원 (서버 `RoundApplicationStatisticsResponse`).
public struct ProjectRoundApplicationStatisticsDTO: Codable {
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let appliedMemberCount: String
    let availableMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case matchingRound, appliedMemberCount, availableMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self,
            forKey: .matchingRound
        )
        appliedMemberCount = try container.decodeProjectCount(forKey: .appliedMemberCount)
        availableMemberCount = try container.decodeProjectCount(forKey: .availableMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encode(appliedMemberCount, forKey: .appliedMemberCount)
        try container.encode(availableMemberCount, forKey: .availableMemberCount)
    }

    func toDomain() -> ProjectRoundApplicationStatistics {
        ProjectRoundApplicationStatistics(
            matchingRound: matchingRound?.toDomain(),
            appliedMemberCount: appliedMemberCount,
            availableMemberCount: availableMemberCount
        )
    }
}

/// 차수별 학교 지원자 수 (서버 `RoundSchoolApplicationStatisticsResponse`).
public struct ProjectRoundSchoolStatisticsDTO: Codable {
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let schools: [SchoolDTO]

    private enum CodingKeys: String, CodingKey {
        case matchingRound, schools
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self,
            forKey: .matchingRound
        )
        schools = try container.decodeIfPresent([SchoolDTO].self, forKey: .schools) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encode(schools, forKey: .schools)
    }

    func toDomain() -> ProjectRoundSchoolStatistics {
        ProjectRoundSchoolStatistics(
            matchingRound: matchingRound?.toDomain(),
            schools: schools.map { $0.toDomain() }
        )
    }

    /// 학교 하나의 지원자 수.
    public struct SchoolDTO: Codable {
        let schoolId: String
        let applicantCount: String

        private enum CodingKeys: String, CodingKey {
            case schoolId, applicantCount
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            schoolId = try container.decodeFlexibleString(forKey: .schoolId)
            applicantCount = try container.decodeProjectCount(forKey: .applicantCount)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(schoolId, forKey: .schoolId)
            try container.encode(applicantCount, forKey: .applicantCount)
        }

        func toDomain() -> ProjectSchoolApplicantCount {
            ProjectSchoolApplicantCount(schoolId: schoolId, applicantCount: applicantCount)
        }
    }
}

/// 학교별 매칭 인원. 지원 통계 요약에는 `appliedMemberCount` 가 더 붙는다.
public struct ProjectSchoolMatchingStatisticsDTO: Codable {
    let schoolId: String
    let matchedMemberCount: String
    let totalMemberCount: String
    let appliedMemberCount: String?

    private enum CodingKeys: String, CodingKey {
        case schoolId, matchedMemberCount, totalMemberCount, appliedMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try container.decodeFlexibleString(forKey: .schoolId)
        matchedMemberCount = try container.decodeProjectCount(forKey: .matchedMemberCount)
        totalMemberCount = try container.decodeProjectCount(forKey: .totalMemberCount)
        appliedMemberCount = try container.decodeFlexibleStringIfPresent(
            forKey: .appliedMemberCount
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try container.encode(totalMemberCount, forKey: .totalMemberCount)
        try container.encodeIfPresent(appliedMemberCount, forKey: .appliedMemberCount)
    }

    func toDomain() -> ProjectSchoolMatchingStatistics {
        ProjectSchoolMatchingStatistics(
            schoolId: schoolId,
            matchedMemberCount: matchedMemberCount,
            totalMemberCount: totalMemberCount,
            appliedMemberCount: appliedMemberCount
        )
    }
}

/// 프로젝트별 차수 인원 (서버 `ProjectRoundMemberStatisticsResponse`).
public struct ProjectRoundMemberStatisticsDTO: Codable {
    let projectId: String
    let matchingRounds: [RoundDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId, matchingRounds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        matchingRounds = try container.decodeIfPresent(
            [RoundDTO].self,
            forKey: .matchingRounds
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(matchingRounds, forKey: .matchingRounds)
    }

    func toDomain() -> ProjectRoundMemberStatistics {
        ProjectRoundMemberStatistics(
            projectId: projectId,
            matchingRounds: matchingRounds.map { $0.toDomain() }
        )
    }

    /// 차수 하나의 지원·매칭 인원.
    public struct RoundDTO: Codable {
        let matchingRound: ProjectMatchingRoundBriefDTO?
        let appliedMemberCount: String
        let matchedMemberCount: String

        private enum CodingKeys: String, CodingKey {
            case matchingRound, appliedMemberCount, matchedMemberCount
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            matchingRound = try container.decodeIfPresent(
                ProjectMatchingRoundBriefDTO.self,
                forKey: .matchingRound
            )
            appliedMemberCount = try container.decodeProjectCount(forKey: .appliedMemberCount)
            matchedMemberCount = try container.decodeProjectCount(forKey: .matchedMemberCount)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
            try container.encode(appliedMemberCount, forKey: .appliedMemberCount)
            try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        }

        func toDomain() -> ProjectRoundMemberCount {
            ProjectRoundMemberCount(
                matchingRound: matchingRound?.toDomain(),
                appliedMemberCount: appliedMemberCount,
                matchedMemberCount: matchedMemberCount
            )
        }
    }
}

// MARK: - 매칭 통계

/// 서버 `ChapterProjectMatchingStatisticsResponse`.
public struct ProjectChapterMatchingStatisticsResponseDTO: Codable {
    let chapterId: String
    let roundMatchingStatistics: [RoundDTO]
    let schoolMatchingStatistics: [ProjectSchoolMatchingStatisticsDTO]
    let unclassifiedMatchingStatistics: UnclassifiedDTO?

    private enum CodingKeys: String, CodingKey {
        case chapterId, roundMatchingStatistics, schoolMatchingStatistics
        case unclassifiedMatchingStatistics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decodeFlexibleString(forKey: .chapterId)
        roundMatchingStatistics = try container.decodeIfPresent(
            [RoundDTO].self,
            forKey: .roundMatchingStatistics
        ) ?? []
        schoolMatchingStatistics = try container.decodeIfPresent(
            [ProjectSchoolMatchingStatisticsDTO].self,
            forKey: .schoolMatchingStatistics
        ) ?? []
        unclassifiedMatchingStatistics = try container.decodeIfPresent(
            UnclassifiedDTO.self,
            forKey: .unclassifiedMatchingStatistics
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chapterId, forKey: .chapterId)
        try container.encode(roundMatchingStatistics, forKey: .roundMatchingStatistics)
        try container.encode(schoolMatchingStatistics, forKey: .schoolMatchingStatistics)
        try container.encodeIfPresent(
            unclassifiedMatchingStatistics,
            forKey: .unclassifiedMatchingStatistics
        )
    }

    public func toDomain() -> ProjectChapterMatchingStatistics {
        ProjectChapterMatchingStatistics(
            chapterId: chapterId,
            roundMatchingStatistics: roundMatchingStatistics.map { $0.toDomain() },
            schoolMatchingStatistics: schoolMatchingStatistics.map { $0.toDomain() },
            unclassifiedMatchingStatistics: unclassifiedMatchingStatistics?.toDomain()
        )
    }

    /// 차수별 매칭 인원.
    public struct RoundDTO: Codable {
        let matchingRound: ProjectMatchingRoundBriefDTO?
        let matchedMemberCount: String
        let availableMemberCount: String
        let projects: [ProjectMatchingCountDTO]

        private enum CodingKeys: String, CodingKey {
            case matchingRound, matchedMemberCount, availableMemberCount, projects
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            matchingRound = try container.decodeIfPresent(
                ProjectMatchingRoundBriefDTO.self,
                forKey: .matchingRound
            )
            matchedMemberCount = try container.decodeProjectCount(forKey: .matchedMemberCount)
            availableMemberCount = try container.decodeProjectCount(forKey: .availableMemberCount)
            projects = try container.decodeIfPresent(
                [ProjectMatchingCountDTO].self,
                forKey: .projects
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
            try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
            try container.encode(availableMemberCount, forKey: .availableMemberCount)
            try container.encode(projects, forKey: .projects)
        }

        func toDomain() -> ProjectRoundMatchingStatistics {
            ProjectRoundMatchingStatistics(
                matchingRound: matchingRound?.toDomain(),
                matchedMemberCount: matchedMemberCount,
                availableMemberCount: availableMemberCount,
                projects: projects.map { $0.toDomain() }
            )
        }
    }

    /// 차수 미분류 인원.
    public struct UnclassifiedDTO: Codable {
        let matchedMemberCount: String
        let projects: [ProjectMatchingCountDTO]

        private enum CodingKeys: String, CodingKey {
            case matchedMemberCount, projects
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            matchedMemberCount = try container.decodeProjectCount(forKey: .matchedMemberCount)
            projects = try container.decodeIfPresent(
                [ProjectMatchingCountDTO].self,
                forKey: .projects
            ) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
            try container.encode(projects, forKey: .projects)
        }

        func toDomain() -> ProjectUnclassifiedMatchingStatistics {
            ProjectUnclassifiedMatchingStatistics(
                matchedMemberCount: matchedMemberCount,
                projects: projects.map { $0.toDomain() }
            )
        }
    }
}

/// 프로젝트 하나의 매칭 인원.
public struct ProjectMatchingCountDTO: Codable {
    let projectId: String
    let matchedMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case projectId, matchedMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        matchedMemberCount = try container.decodeProjectCount(forKey: .matchedMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
    }

    func toDomain() -> ProjectMatchingCount {
        ProjectMatchingCount(projectId: projectId, matchedMemberCount: matchedMemberCount)
    }
}
