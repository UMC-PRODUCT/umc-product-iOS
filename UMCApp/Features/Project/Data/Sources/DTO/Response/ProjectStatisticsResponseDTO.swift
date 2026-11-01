//
//  ProjectStatisticsResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 11/1/26.
//

import Foundation
import UMCFoundation
import ProjectDomain

/// 프로젝트 지원 통계.
public struct ProjectChapterStatisticsResponseDTO: Codable {
    let chapterId: String
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let summary: ProjectApplicationStatisticsSummaryDTO

    private enum CodingKeys: String, CodingKey {
        case chapterId
        case matchingRound
        case summary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decodeFlexibleString(forKey: .chapterId)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self, forKey: .matchingRound
        )
        summary = try container.decode(
            ProjectApplicationStatisticsSummaryDTO.self, forKey: .summary
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chapterId, forKey: .chapterId)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encode(summary, forKey: .summary)
    }

    public func toDomain() -> ProjectChapterStatistics {
        ProjectChapterStatistics(
            chapterId: chapterId,
            matchingRound: matchingRound?.toDomain(),
            summary: summary.toDomain()
        )
    }
}

/// 차수·학교·프로젝트별 지원 현황.
public struct ProjectApplicationStatisticsSummaryDTO: Codable {
    let roundApplicationStatistics: [ProjectRoundApplicationStatisticsDTO]
    let schoolApplicationStatistics: [ProjectSchoolApplicationStatisticsDTO]
    let projectRoundStatistics: [ProjectApplicationProjectStatisticsDTO]

    private enum CodingKeys: String, CodingKey {
        case roundApplicationStatistics
        case schoolApplicationStatistics
        case projectRoundStatistics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roundApplicationStatistics = try container.decode(
            [ProjectRoundApplicationStatisticsDTO].self, forKey: .roundApplicationStatistics
        )
        schoolApplicationStatistics = try container.decode(
            [ProjectSchoolApplicationStatisticsDTO].self, forKey: .schoolApplicationStatistics
        )
        projectRoundStatistics = try container.decode(
            [ProjectApplicationProjectStatisticsDTO].self, forKey: .projectRoundStatistics
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(roundApplicationStatistics, forKey: .roundApplicationStatistics)
        try container.encode(schoolApplicationStatistics, forKey: .schoolApplicationStatistics)
        try container.encode(projectRoundStatistics, forKey: .projectRoundStatistics)
    }

    public func toDomain() -> ProjectStatisticsSummary {
        ProjectStatisticsSummary(
            roundApplicationStatistics: roundApplicationStatistics.map { $0.toDomain() },
            schoolApplicationStatistics: schoolApplicationStatistics.map { $0.toDomain() },
            projectRoundStatistics: projectRoundStatistics.map { $0.toDomain() }
        )
    }
}

/// 차수별 지원 인원.
public struct ProjectRoundApplicationStatisticsDTO: Codable {
    let matchingRound: ProjectMatchingRoundBriefDTO?
    let appliedMemberCount: String
    let availableMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case matchingRound
        case appliedMemberCount
        case availableMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchingRound = try container.decodeIfPresent(
            ProjectMatchingRoundBriefDTO.self, forKey: .matchingRound
        )
        appliedMemberCount = try container.decodeFlexibleString(forKey: .appliedMemberCount)
        availableMemberCount = try container.decodeFlexibleString(forKey: .availableMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try container.encode(appliedMemberCount, forKey: .appliedMemberCount)
        try container.encode(availableMemberCount, forKey: .availableMemberCount)
    }

    public func toDomain() -> ProjectRoundApplicationStatistics {
        ProjectRoundApplicationStatistics(
            matchingRound: matchingRound?.toDomain(),
            appliedMemberCount: appliedMemberCount,
            availableMemberCount: availableMemberCount
        )
    }
}

/// 학교별 지원 가능 총원과 차수별 지원 인원.
public struct ProjectSchoolApplicationStatisticsDTO: Codable {
    let schoolId: String
    let schoolName: String
    let totalMemberCount: String
    let rounds: [ProjectApplicationPhaseCountDTO]

    private enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
        case totalMemberCount
        case rounds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try container.decodeFlexibleString(forKey: .schoolId)
        schoolName = try container.decode(String.self, forKey: .schoolName)
        totalMemberCount = try container.decodeFlexibleString(forKey: .totalMemberCount)
        rounds = try container.decode([ProjectApplicationPhaseCountDTO].self, forKey: .rounds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(schoolName, forKey: .schoolName)
        try container.encode(totalMemberCount, forKey: .totalMemberCount)
        try container.encode(rounds, forKey: .rounds)
    }

    public func toDomain() -> ProjectSchoolApplicationStatistics {
        ProjectSchoolApplicationStatistics(
            schoolId: schoolId,
            schoolName: schoolName,
            totalMemberCount: totalMemberCount,
            rounds: rounds.map { $0.toDomain() }
        )
    }
}

/// 프로젝트별 차수별 지원 인원.
public struct ProjectApplicationProjectStatisticsDTO: Codable {
    let projectId: String
    let projectName: String
    let rounds: [ProjectApplicationPhaseCountDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId
        case projectName
        case rounds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        projectName = try container.decode(String.self, forKey: .projectName)
        rounds = try container.decode([ProjectApplicationPhaseCountDTO].self, forKey: .rounds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(rounds, forKey: .rounds)
    }

    public func toDomain() -> ProjectApplicationProjectStatistics {
        ProjectApplicationProjectStatistics(
            projectId: projectId,
            projectName: projectName,
            rounds: rounds.map { $0.toDomain() }
        )
    }
}

/// 차수별 지원 인원.
public struct ProjectApplicationPhaseCountDTO: Codable {
    let phase: String
    let applicantCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case applicantCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(String.self, forKey: .phase)
        applicantCount = try container.decodeFlexibleString(forKey: .applicantCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phase, forKey: .phase)
        try container.encode(applicantCount, forKey: .applicantCount)
    }

    public func toDomain() -> ProjectApplicationPhaseCount {
        ProjectApplicationPhaseCount(
            phase: ProjectMatchingPhase(rawValue: phase) ?? .unknown,
            applicantCount: applicantCount
        )
    }
}

/// 공개된 매칭 결과 집계.
public struct ProjectChapterMatchingStatisticsResponseDTO: Codable {
    let chapterId: String
    let roundMatchingStatistics: [ProjectRoundMatchingStatisticsDTO]
    let schoolMatchingStatistics: [ProjectSchoolMatchingStatisticsDTO]
    let projectMatchingStatistics: [ProjectMatchingProjectStatisticsDTO]

    private enum CodingKeys: String, CodingKey {
        case chapterId
        case roundMatchingStatistics
        case schoolMatchingStatistics
        case projectMatchingStatistics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decodeFlexibleString(forKey: .chapterId)
        roundMatchingStatistics = try container.decode(
            [ProjectRoundMatchingStatisticsDTO].self, forKey: .roundMatchingStatistics
        )
        schoolMatchingStatistics = try container.decode(
            [ProjectSchoolMatchingStatisticsDTO].self, forKey: .schoolMatchingStatistics
        )
        projectMatchingStatistics = try container.decode(
            [ProjectMatchingProjectStatisticsDTO].self, forKey: .projectMatchingStatistics
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chapterId, forKey: .chapterId)
        try container.encode(roundMatchingStatistics, forKey: .roundMatchingStatistics)
        try container.encode(schoolMatchingStatistics, forKey: .schoolMatchingStatistics)
        try container.encode(projectMatchingStatistics, forKey: .projectMatchingStatistics)
    }

    public func toDomain() -> ProjectChapterMatchingStatistics {
        ProjectChapterMatchingStatistics(
            chapterId: chapterId,
            roundMatchingStatistics: roundMatchingStatistics.map { $0.toDomain() },
            schoolMatchingStatistics: schoolMatchingStatistics.map { $0.toDomain() },
            projectMatchingStatistics: projectMatchingStatistics.map { $0.toDomain() }
        )
    }
}

/// 차수별 매칭 인원. 랜덤 매칭도 phase로 구분한다.
public struct ProjectRoundMatchingStatisticsDTO: Codable {
    let phase: String
    let matchedMemberCount: String
    let availableMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case matchedMemberCount
        case availableMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(String.self, forKey: .phase)
        matchedMemberCount = try container.decodeFlexibleString(forKey: .matchedMemberCount)
        availableMemberCount = try container.decodeFlexibleString(forKey: .availableMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phase, forKey: .phase)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try container.encode(availableMemberCount, forKey: .availableMemberCount)
    }

    public func toDomain() -> ProjectRoundMatchingStatistics {
        ProjectRoundMatchingStatistics(
            phase: ProjectMatchingPhase(rawValue: phase) ?? .unknown,
            matchedMemberCount: matchedMemberCount,
            availableMemberCount: availableMemberCount
        )
    }
}

/// 학교별 누적 매칭 인원과 대상 총원.
public struct ProjectSchoolMatchingStatisticsDTO: Codable {
    let schoolId: String
    let schoolName: String
    let matchedMemberCount: String
    let totalMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
        case matchedMemberCount
        case totalMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try container.decodeFlexibleString(forKey: .schoolId)
        schoolName = try container.decode(String.self, forKey: .schoolName)
        matchedMemberCount = try container.decodeFlexibleString(forKey: .matchedMemberCount)
        totalMemberCount = try container.decodeFlexibleString(forKey: .totalMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(schoolName, forKey: .schoolName)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try container.encode(totalMemberCount, forKey: .totalMemberCount)
    }

    public func toDomain() -> ProjectSchoolMatchingStatistics {
        ProjectSchoolMatchingStatistics(
            schoolId: schoolId,
            schoolName: schoolName,
            matchedMemberCount: matchedMemberCount,
            totalMemberCount: totalMemberCount
        )
    }
}

/// 프로젝트별 누적 매칭 인원 및 정원.
public struct ProjectMatchingProjectStatisticsDTO: Codable {
    let projectId: String
    let projectName: String
    let matchedMemberCount: String
    let quota: String
    let rounds: [ProjectMatchingPhaseCountDTO]
    let parts: [ProjectMatchingPartStatisticsDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId
        case projectName
        case matchedMemberCount
        case quota
        case rounds
        case parts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        projectName = try container.decode(String.self, forKey: .projectName)
        matchedMemberCount = try container.decodeFlexibleString(forKey: .matchedMemberCount)
        quota = try container.decodeFlexibleString(forKey: .quota)
        rounds = try container.decode([ProjectMatchingPhaseCountDTO].self, forKey: .rounds)
        parts = try container.decode([ProjectMatchingPartStatisticsDTO].self, forKey: .parts)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try container.encode(quota, forKey: .quota)
        try container.encode(rounds, forKey: .rounds)
        try container.encode(parts, forKey: .parts)
    }

    public func toDomain() -> ProjectMatchingProjectStatistics {
        ProjectMatchingProjectStatistics(
            projectId: projectId,
            projectName: projectName,
            matchedMemberCount: matchedMemberCount,
            quota: quota,
            rounds: rounds.map { $0.toDomain() },
            parts: parts.map { $0.toDomain() }
        )
    }
}

/// 차수별 매칭 완료 인원.
public struct ProjectMatchingPhaseCountDTO: Codable {
    let phase: String
    let matchedMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case matchedMemberCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        phase = try container.decode(String.self, forKey: .phase)
        matchedMemberCount = try container.decodeFlexibleString(forKey: .matchedMemberCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phase, forKey: .phase)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
    }

    public func toDomain() -> ProjectMatchingPhaseCount {
        ProjectMatchingPhaseCount(
            phase: ProjectMatchingPhase(rawValue: phase) ?? .unknown,
            matchedMemberCount: matchedMemberCount
        )
    }
}

/// 파트별 매칭 완료 인원과 정원.
public struct ProjectMatchingPartStatisticsDTO: Codable {
    let part: String?
    let matchedMemberCount: String
    let quota: String

    private enum CodingKeys: String, CodingKey {
        case part
        case matchedMemberCount
        case quota
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        part = try container.decodeIfPresent(String.self, forKey: .part)
        matchedMemberCount = try container.decodeFlexibleString(forKey: .matchedMemberCount)
        quota = try container.decodeFlexibleString(forKey: .quota)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(part, forKey: .part)
        try container.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try container.encode(quota, forKey: .quota)
    }

    public func toDomain() -> ProjectMatchingPartStatistics {
        ProjectMatchingPartStatistics(
            part: part.flatMap(UMCPartType.init(apiValue:)),
            matchedMemberCount: matchedMemberCount,
            quota: quota
        )
    }
}
