//
//  ProjectResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 조회·관리 응답 DTO 모음. 서버가 정수를 문자열로 직렬화하므로 id·수량은
//  `decodeFlexibleString*` 으로 받아 `String` 으로 둔다(핵심 규칙 #2·#3).
//  enum·파트는 원문 문자열로 저장하고 `toDomain()` 에서 해석한다 — 서버가 값을 추가해도
//  디코딩 자체는 실패하지 않는다.
//

import Foundation
import UMCFoundation
import ProjectDomain

// MARK: - Common

extension KeyedDecodingContainer {
    /// 인원 수·TO 처럼 서버가 원시 `long` 으로 주는 값. 빠져 있으면 `"0"`, 숫자가 아니면 throw.
    func decodeProjectCount(forKey key: Key) throws -> String {
        try decodeFlexibleStringIfPresent(forKey: key) ?? "0"
    }
}

/// 서버 `MemberBrief`.
public struct ProjectMemberBriefDTO: Codable {
    let memberId: String
    let nickname: String?
    let name: String?
    let schoolName: String?

    private enum CodingKeys: String, CodingKey {
        case memberId, nickname, name, schoolName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decodeFlexibleString(forKey: .memberId)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberId, forKey: .memberId)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(schoolName, forKey: .schoolName)
    }

    public func toDomain() -> ProjectMemberBrief {
        ProjectMemberBrief(
            memberId: memberId,
            nickname: nickname,
            name: name,
            schoolName: schoolName
        )
    }
}

/// 매칭 차수 요약. 팀 구성·지원서는 `id`, 통계는 `matchingRoundId` 키로 온다.
public struct ProjectMatchingRoundBriefDTO: Codable {
    let id: String?
    let type: String?
    let phase: String?

    private enum CodingKeys: String, CodingKey {
        case id, matchingRoundId, type, phase
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFirstNonEmptyString(forKeys: [.id, .matchingRoundId])
        type = try container.decodeIfPresent(String.self, forKey: .type)
        phase = try container.decodeIfPresent(String.self, forKey: .phase)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(phase, forKey: .phase)
    }

    public func toDomain() -> ProjectMatchingRoundBrief {
        ProjectMatchingRoundBrief(
            id: id,
            type: type.map { ProjectMatchingType(rawValue: $0) ?? .unknown },
            phase: phase.map { ProjectMatchingPhase(rawValue: $0) ?? .unknown }
        )
    }
}

/// 서버 `PartQuotaInfo`.
public struct ProjectPartQuotaDTO: Codable {
    let part: String
    let currentCount: String
    let quota: String
    let status: String?

    private enum CodingKeys: String, CodingKey {
        case part, currentCount, quota, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        part = try container.decode(String.self, forKey: .part)
        currentCount = try container.decodeProjectCount(forKey: .currentCount)
        quota = try container.decodeProjectCount(forKey: .quota)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(part, forKey: .part)
        try container.encode(currentCount, forKey: .currentCount)
        try container.encode(quota, forKey: .quota)
        try container.encodeIfPresent(status, forKey: .status)
    }

    /// 모르는 파트면 `nil` — 호출부가 `compactMap` 으로 걸러낸다.
    public func toDomain() -> ProjectPartQuota? {
        guard let partType = UMCPartType(apiValue: part) else { return nil }
        return ProjectPartQuota(
            part: partType,
            currentCount: currentCount,
            quota: quota,
            status: status.flatMap(ProjectPartQuotaStatus.init(rawValue:)) ?? .unknown
        )
    }
}

// MARK: - Summary · Detail

/// 목록 원소 — 서버 `ProjectSummaryResponse`(`GET /`)와
/// `ManagedProjectSummaryResponse`(`GET /me/managed`, `status` 추가)를 함께 받는다.
public struct ProjectSummaryResponseDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let thumbnailImageUrl: String?
    let status: String?
    let productOwner: ProjectMemberBriefDTO?
    let partQuotas: [ProjectPartQuotaDTO]
    let partQuotaStatus: String?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, thumbnailImageUrl, status, productOwner
        case partQuotas, partQuotaStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        thumbnailImageUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailImageUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        productOwner = try container.decodeIfPresent(
            ProjectMemberBriefDTO.self,
            forKey: .productOwner
        )
        partQuotas = try container.decodeIfPresent(
            [ProjectPartQuotaDTO].self,
            forKey: .partQuotas
        ) ?? []
        partQuotaStatus = try container.decodeIfPresent(String.self, forKey: .partQuotaStatus)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(productOwner, forKey: .productOwner)
        try container.encode(partQuotas, forKey: .partQuotas)
        try container.encodeIfPresent(partQuotaStatus, forKey: .partQuotaStatus)
    }

    public func toDomain() -> ProjectSummary {
        ProjectSummary(
            id: id,
            name: name,
            description: description,
            thumbnailImageURL: thumbnailImageUrl,
            status: status.map { ProjectStatus(rawValue: $0) ?? .unknown },
            productOwner: productOwner?.toDomain(),
            partQuotas: partQuotas.compactMap { $0.toDomain() },
            partQuotaStatus: partQuotaStatus.map {
                ProjectPartQuotaStatus(rawValue: $0) ?? .unknown
            }
        )
    }
}

/// 상세 — 서버 `ProjectDetailResponse`(`GET /{projectId}`)와
/// `DraftProjectResponse`(`GET /me/draft`, `status` 있음·TO 없음)를 함께 받는다.
public struct ProjectDetailResponseDTO: Codable {
    let id: String
    let status: String?
    let name: String
    let description: String?
    let thumbnailImageUrl: String?
    let logoImageUrl: String?
    let externalLink: String?
    let productOwner: ProjectMemberBriefDTO?
    let coProductOwners: [ProjectMemberBriefDTO]
    let partQuotas: [ProjectPartQuotaDTO]
    let partQuotaStatus: String?
    let applicationFormId: String?

    private enum CodingKeys: String, CodingKey {
        case id, status, name, description, thumbnailImageUrl, logoImageUrl, externalLink
        case productOwner, coProductOwners, partQuotas, partQuotaStatus, applicationFormId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        // 임시저장 프로젝트는 이름이 비어 있을 수 있다.
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        thumbnailImageUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailImageUrl)
        logoImageUrl = try container.decodeIfPresent(String.self, forKey: .logoImageUrl)
        externalLink = try container.decodeIfPresent(String.self, forKey: .externalLink)
        productOwner = try container.decodeIfPresent(
            ProjectMemberBriefDTO.self,
            forKey: .productOwner
        )
        coProductOwners = try container.decodeIfPresent(
            [ProjectMemberBriefDTO].self,
            forKey: .coProductOwners
        ) ?? []
        partQuotas = try container.decodeIfPresent(
            [ProjectPartQuotaDTO].self,
            forKey: .partQuotas
        ) ?? []
        partQuotaStatus = try container.decodeIfPresent(String.self, forKey: .partQuotaStatus)
        applicationFormId = try container.decodeFlexibleStringIfPresent(forKey: .applicationFormId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
        try container.encodeIfPresent(logoImageUrl, forKey: .logoImageUrl)
        try container.encodeIfPresent(externalLink, forKey: .externalLink)
        try container.encodeIfPresent(productOwner, forKey: .productOwner)
        try container.encode(coProductOwners, forKey: .coProductOwners)
        try container.encode(partQuotas, forKey: .partQuotas)
        try container.encodeIfPresent(partQuotaStatus, forKey: .partQuotaStatus)
        try container.encodeIfPresent(applicationFormId, forKey: .applicationFormId)
    }

    public func toDomain() -> ProjectDetail {
        ProjectDetail(
            id: id,
            status: status.map { ProjectStatus(rawValue: $0) ?? .unknown },
            name: name,
            description: description,
            thumbnailImageURL: thumbnailImageUrl,
            logoImageURL: logoImageUrl,
            externalLink: externalLink,
            productOwner: productOwner?.toDomain(),
            coProductOwners: coProductOwners.map { $0.toDomain() },
            partQuotas: partQuotas.compactMap { $0.toDomain() },
            partQuotaStatus: partQuotaStatus.map {
                ProjectPartQuotaStatus(rawValue: $0) ?? .unknown
            },
            applicationFormId: applicationFormId
        )
    }
}

/// 서버 `ProjectStatusResponse` — 생성·수정·상태 전이 공통 응답.
public struct ProjectStatusResponseDTO: Codable {
    let projectId: String
    let status: String

    private enum CodingKeys: String, CodingKey {
        case projectId, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        status = try container.decode(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(status, forKey: .status)
    }

    public func toDomain() -> ProjectStatusResult {
        ProjectStatusResult(
            projectId: projectId,
            status: ProjectStatus(rawValue: status) ?? .unknown
        )
    }
}

/// `POST /{projectId}/members` 의 `Long` 결과(추가된 팀원 id). 문자열·숫자 모두 받는다.
public struct ProjectIdentifierResponseDTO: Codable {
    let value: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            value = String(try container.decode(Int64.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Members

/// 서버 `ProjectMembersResponse`.
public struct ProjectMembersResponseDTO: Codable {
    let projectId: String
    let productOwner: MemberDTO?
    let coProductOwners: [MemberDTO]
    let partGroups: [PartGroupDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId, productOwner, coProductOwners, partGroups
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        productOwner = try container.decodeIfPresent(MemberDTO.self, forKey: .productOwner)
        coProductOwners = try container.decodeIfPresent(
            [MemberDTO].self,
            forKey: .coProductOwners
        ) ?? []
        partGroups = try container.decodeIfPresent(
            [PartGroupDTO].self,
            forKey: .partGroups
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encodeIfPresent(productOwner, forKey: .productOwner)
        try container.encode(coProductOwners, forKey: .coProductOwners)
        try container.encode(partGroups, forKey: .partGroups)
    }

    public func toDomain() -> ProjectMembers {
        ProjectMembers(
            projectId: projectId,
            productOwner: productOwner?.toDomain(),
            coProductOwners: coProductOwners.map { $0.toDomain() },
            partGroups: partGroups.compactMap { $0.toDomain() }
        )
    }

    /// 파트별 팀원 묶음.
    public struct PartGroupDTO: Codable {
        let part: String
        let members: [MemberDTO]

        private enum CodingKeys: String, CodingKey {
            case part, members
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            part = try container.decode(String.self, forKey: .part)
            members = try container.decodeIfPresent([MemberDTO].self, forKey: .members) ?? []
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(part, forKey: .part)
            try container.encode(members, forKey: .members)
        }

        func toDomain() -> ProjectPartMembers? {
            guard let partType = UMCPartType(apiValue: part) else { return nil }
            return ProjectPartMembers(part: partType, members: members.map { $0.toDomain() })
        }
    }

    /// 팀원 한 명. 차수 없이 들어온 팀원은 `matchedRoundInfo` 가 `null` 이다.
    public struct MemberDTO: Codable {
        let memberId: String
        let nickname: String?
        let name: String?
        let schoolName: String?
        let matchedRoundInfo: ProjectMatchingRoundBriefDTO?

        private enum CodingKeys: String, CodingKey {
            case memberId, nickname, name, schoolName, matchedRoundInfo
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            memberId = try container.decodeFlexibleString(forKey: .memberId)
            nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName)
            matchedRoundInfo = try container.decodeIfPresent(
                ProjectMatchingRoundBriefDTO.self,
                forKey: .matchedRoundInfo
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(memberId, forKey: .memberId)
            try container.encodeIfPresent(nickname, forKey: .nickname)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(schoolName, forKey: .schoolName)
            try container.encodeIfPresent(matchedRoundInfo, forKey: .matchedRoundInfo)
        }

        func toDomain() -> ProjectTeamMember {
            ProjectTeamMember(
                memberId: memberId,
                nickname: nickname,
                name: name,
                schoolName: schoolName,
                matchedRound: matchedRoundInfo?.toDomain()
            )
        }
    }
}

// MARK: - Page

/// 서버 `PageResponse`.
public struct ProjectPageResponseDTO<Item: Codable>: Codable {
    let content: [Item]
    let page: String
    let size: String
    let totalElements: String
    let totalPages: String
    let hasNext: Bool
    let hasPrevious: Bool

    private enum CodingKeys: String, CodingKey {
        case content, page, size, totalElements, totalPages, hasNext, hasPrevious
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([Item].self, forKey: .content) ?? []
        page = container.decodeFlexibleStringOrEmpty(forKey: .page)
        size = container.decodeFlexibleStringOrEmpty(forKey: .size)
        totalElements = container.decodeFlexibleStringOrEmpty(forKey: .totalElements)
        totalPages = container.decodeFlexibleStringOrEmpty(forKey: .totalPages)
        hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
        hasPrevious = try container.decodeBoolFlexibleIfPresent(forKey: .hasPrevious) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(page, forKey: .page)
        try container.encode(size, forKey: .size)
        try container.encode(totalElements, forKey: .totalElements)
        try container.encode(totalPages, forKey: .totalPages)
        try container.encode(hasNext, forKey: .hasNext)
        try container.encode(hasPrevious, forKey: .hasPrevious)
    }

    public func toDomain<Mapped: Sendable & Equatable>(
        _ transform: (Item) -> Mapped
    ) -> ProjectPage<Mapped> {
        ProjectPage(
            items: content.map(transform),
            page: page,
            size: size,
            totalElements: totalElements,
            totalPages: totalPages,
            hasNext: hasNext,
            hasPrevious: hasPrevious
        )
    }
}
