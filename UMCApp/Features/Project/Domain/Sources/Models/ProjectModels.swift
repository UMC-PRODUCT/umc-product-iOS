//
//  ProjectModels.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 조회·관리 도메인 모델. 서버 정수(id·인원 수)는 전부 `String` 이다 (핵심 규칙 #2).
//

import Foundation
import UMCFoundation

/// 멤버 요약 (서버 `MemberBrief`).
///
/// 서버가 멤버 정보를 못 찾으면 이름류가 `nil` 로 온다.
public struct ProjectMemberBrief: Sendable, Equatable {
    public let memberId: String
    public let nickname: String?
    public let name: String?
    public let schoolName: String?

    public init(memberId: String, nickname: String?, name: String?, schoolName: String?) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.schoolName = schoolName
    }
}

/// 매칭 차수 요약 — `MatchingRoundBrief`·`MatchedRoundInfo`·통계의 `matchingRound` 공용.
///
/// 랜덤 매칭 결과는 차수가 없어 `id` 가 `nil` 이다.
public struct ProjectMatchingRoundBrief: Sendable, Equatable {
    public let id: String?
    public let type: ProjectMatchingType?
    public let phase: ProjectMatchingPhase?

    public init(id: String?, type: ProjectMatchingType?, phase: ProjectMatchingPhase?) {
        self.id = id
        self.type = type
        self.phase = phase
    }
}

/// 파트별 TO (서버 `PartQuotaInfo`).
public struct ProjectPartQuota: Sendable, Equatable {
    public let part: UMCPartType
    public let currentCount: String
    public let quota: String
    public let status: ProjectPartQuotaStatus

    public init(
        part: UMCPartType,
        currentCount: String,
        quota: String,
        status: ProjectPartQuotaStatus
    ) {
        self.part = part
        self.currentCount = currentCount
        self.quota = quota
        self.status = status
    }
}

/// 프로젝트 목록 항목.
///
/// 공개 목록(`ProjectSummaryResponse`)·내가 관리하는 목록(`ManagedProjectSummaryResponse`)·
/// 내 지원 내역의 `project` 가 같이 쓴다. `status` 는 관리 목록에만 온다.
public struct ProjectSummary: Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let thumbnailImageURL: String?
    public let status: ProjectStatus?
    public let productOwner: ProjectMemberBrief?
    public let partQuotas: [ProjectPartQuota]
    /// 파트 TO 가 하나도 없으면 `nil`.
    public let partQuotaStatus: ProjectPartQuotaStatus?

    public init(
        id: String,
        name: String,
        description: String?,
        thumbnailImageURL: String?,
        status: ProjectStatus?,
        productOwner: ProjectMemberBrief?,
        partQuotas: [ProjectPartQuota],
        partQuotaStatus: ProjectPartQuotaStatus?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnailImageURL = thumbnailImageURL
        self.status = status
        self.productOwner = productOwner
        self.partQuotas = partQuotas
        self.partQuotaStatus = partQuotaStatus
    }
}

/// 프로젝트 상세 — `ProjectDetailResponse`·`DraftProjectResponse` 공용.
///
/// 상세에는 `status` 가, 임시저장본에는 `partQuotas`·`partQuotaStatus` 가 없다.
public struct ProjectDetail: Sendable, Equatable {
    public let id: String
    public let status: ProjectStatus?
    public let name: String
    public let description: String?
    public let thumbnailImageURL: String?
    public let logoImageURL: String?
    public let externalLink: String?
    public let productOwner: ProjectMemberBrief?
    public let coProductOwners: [ProjectMemberBrief]
    public let partQuotas: [ProjectPartQuota]
    public let partQuotaStatus: ProjectPartQuotaStatus?
    /// 지원 폼이 아직 없으면 `nil`.
    public let applicationFormId: String?

    public init(
        id: String,
        status: ProjectStatus?,
        name: String,
        description: String?,
        thumbnailImageURL: String?,
        logoImageURL: String?,
        externalLink: String?,
        productOwner: ProjectMemberBrief?,
        coProductOwners: [ProjectMemberBrief],
        partQuotas: [ProjectPartQuota],
        partQuotaStatus: ProjectPartQuotaStatus?,
        applicationFormId: String?
    ) {
        self.id = id
        self.status = status
        self.name = name
        self.description = description
        self.thumbnailImageURL = thumbnailImageURL
        self.logoImageURL = logoImageURL
        self.externalLink = externalLink
        self.productOwner = productOwner
        self.coProductOwners = coProductOwners
        self.partQuotas = partQuotas
        self.partQuotaStatus = partQuotaStatus
        self.applicationFormId = applicationFormId
    }
}

/// 상태 전이 명령의 결과 (서버 `ProjectStatusResponse`).
public struct ProjectStatusResult: Sendable, Equatable {
    public let projectId: String
    public let status: ProjectStatus

    public init(projectId: String, status: ProjectStatus) {
        self.projectId = projectId
        self.status = status
    }
}

/// 프로젝트 팀원 (서버 `ProjectMembersResponse.ProjectMemberBrief`).
public struct ProjectTeamMember: Sendable, Equatable {
    public let memberId: String
    public let nickname: String?
    public let name: String?
    public let schoolName: String?
    /// 매칭으로 합류했으면 그 차수, PO·직접 추가면 `nil`.
    public let matchedRound: ProjectMatchingRoundBrief?

    public init(
        memberId: String,
        nickname: String?,
        name: String?,
        schoolName: String?,
        matchedRound: ProjectMatchingRoundBrief?
    ) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.schoolName = schoolName
        self.matchedRound = matchedRound
    }
}

/// 파트별 팀원 묶음.
public struct ProjectPartMembers: Sendable, Equatable {
    public let part: UMCPartType
    public let members: [ProjectTeamMember]

    public init(part: UMCPartType, members: [ProjectTeamMember]) {
        self.part = part
        self.members = members
    }
}

/// 프로젝트 팀 구성 (서버 `ProjectMembersResponse`).
public struct ProjectMembers: Sendable, Equatable {
    public let projectId: String
    public let productOwner: ProjectTeamMember?
    public let coProductOwners: [ProjectTeamMember]
    public let partGroups: [ProjectPartMembers]

    public init(
        projectId: String,
        productOwner: ProjectTeamMember?,
        coProductOwners: [ProjectTeamMember],
        partGroups: [ProjectPartMembers]
    ) {
        self.projectId = projectId
        self.productOwner = productOwner
        self.coProductOwners = coProductOwners
        self.partGroups = partGroups
    }
}

/// 서버 `PageResponse` — 페이지 메타도 서버 정수라 `String` 이다.
public struct ProjectPage<Item: Sendable & Equatable>: Sendable, Equatable {
    public let items: [Item]
    public let page: String
    public let size: String
    public let totalElements: String
    public let totalPages: String
    public let hasNext: Bool
    public let hasPrevious: Bool

    public init(
        items: [Item],
        page: String,
        size: String,
        totalElements: String,
        totalPages: String,
        hasNext: Bool,
        hasPrevious: Bool
    ) {
        self.items = items
        self.page = page
        self.size = size
        self.totalElements = totalElements
        self.totalPages = totalPages
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
    }
}

/// 프로젝트 목록 검색 조건 (`GET /api/v1/projects`).
///
/// `statuses` 가 비어 있으면 서버가 `IN_PROGRESS` 만 돌려준다.
/// `sort` 가 비어 있으면 서버 기본값 `createdAt,name` 오름차순.
public struct ProjectSearchQuery: Sendable, Equatable {
    public let gisuId: String
    public let keyword: String?
    public let chapterId: String?
    public let schoolIds: [String]
    public let parts: [UMCPartType]
    public let partQuotaStatus: ProjectPartQuotaStatus?
    public let statuses: [ProjectStatus]
    public let page: Int
    public let size: Int
    public let sort: [String]

    public init(
        gisuId: String,
        keyword: String? = nil,
        chapterId: String? = nil,
        schoolIds: [String] = [],
        parts: [UMCPartType] = [],
        partQuotaStatus: ProjectPartQuotaStatus? = nil,
        statuses: [ProjectStatus] = [],
        page: Int = 0,
        size: Int = 20,
        sort: [String] = []
    ) {
        self.gisuId = gisuId
        self.keyword = keyword
        self.chapterId = chapterId
        self.schoolIds = schoolIds
        self.parts = parts
        self.partQuotaStatus = partQuotaStatus
        self.statuses = statuses
        self.page = page
        self.size = size
        self.sort = sort
    }
}

/// 프로젝트 기본 정보 수정 (`PATCH /api/v1/projects/{projectId}`).
///
/// `nil` 인 필드는 요청에서 빠져 서버 값을 그대로 둔다.
public struct ProjectInfoUpdate: Sendable, Equatable {
    public let name: String?
    public let description: String?
    public let externalLink: String?
    public let thumbnailFileId: String?
    public let logoFileId: String?

    public init(
        name: String? = nil,
        description: String? = nil,
        externalLink: String? = nil,
        thumbnailFileId: String? = nil,
        logoFileId: String? = nil
    ) {
        self.name = name
        self.description = description
        self.externalLink = externalLink
        self.thumbnailFileId = thumbnailFileId
        self.logoFileId = logoFileId
    }
}

/// 파트 TO 설정 항목 (`PUT /api/v1/projects/{projectId}/part-quotas`). `quota` 는 1 이상.
public struct ProjectPartQuotaEntry: Sendable, Equatable {
    public let part: UMCPartType
    public let quota: String

    public init(part: UMCPartType, quota: String) {
        self.part = part
        self.quota = quota
    }
}
