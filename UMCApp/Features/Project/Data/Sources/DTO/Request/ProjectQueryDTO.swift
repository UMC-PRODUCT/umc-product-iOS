//
//  ProjectQueryDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 API 쿼리 파라미터 DTO 모음. `toParameters` 결과를 라우터가
//  `ProjectRouter.queryEncoding`(배열 `noBrackets`)으로 싣는다.
//  쿼리스트링은 문자열이라 id 를 `String` 그대로 싣는다.
//

import Foundation
import UMCFoundation
import ProjectDomain

/// 프로젝트 목록 검색 (`GET /api/v1/projects`).
public struct ProjectSearchQueryDTO: Encodable, Equatable {
    public let gisuId: String
    public let keyword: String?
    public let chapterId: String?
    public let schoolIds: [String]
    public let parts: [String]
    public let partQuotaStatus: String?
    public let statuses: [String]
    public let page: Int
    public let size: Int
    public let sort: [String]

    public init(query: ProjectSearchQuery) {
        self.gisuId = query.gisuId
        self.keyword = query.keyword
        self.chapterId = query.chapterId
        self.schoolIds = query.schoolIds
        self.parts = query.parts.map(\.apiValue)
        self.partQuotaStatus = query.partQuotaStatus?.rawValue
        self.statuses = query.statuses.map(\.rawValue)
        self.page = query.page
        self.size = query.size
        self.sort = query.sort
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = ["gisuId": gisuId, "page": page, "size": size]
        params["keyword"] = keyword
        params["chapterId"] = chapterId
        params["partQuotaStatus"] = partQuotaStatus
        if !schoolIds.isEmpty { params["schoolIds"] = schoolIds }
        if !parts.isEmpty { params["parts"] = parts }
        if !statuses.isEmpty { params["statuses"] = statuses }
        if !sort.isEmpty { params["sort"] = sort }
        return params
    }
}

/// 내가 관리하는 프로젝트 목록 (`GET /me/managed`).
public struct ProjectManagedQueryDTO: Encodable, Equatable {
    public let gisuId: String
    public let keyword: String?
    public let page: Int
    public let size: Int

    public init(gisuId: String, keyword: String?, page: Int, size: Int) {
        self.gisuId = gisuId
        self.keyword = keyword
        self.page = page
        self.size = size
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = ["gisuId": gisuId, "page": page, "size": size]
        params["keyword"] = keyword
        return params
    }
}

/// 기수 하나로 거르는 조회 (`GET /me/draft`).
public struct ProjectGisuQueryDTO: Encodable, Equatable {
    public let gisuId: String

    public init(gisuId: String) {
        self.gisuId = gisuId
    }

    public var toParameters: [String: Any] {
        ["gisuId": gisuId]
    }
}

/// 여러 프로젝트를 한 번에 조회 (`GET /members`·`GET /permissions`).
///
/// 서버 파라미터 이름이 엔드포인트마다 달라(`projectIds`·`ids`) 이름을 받는다.
public struct ProjectIdsQueryDTO: Encodable, Equatable {
    public let parameterName: String
    public let projectIds: [String]

    public init(parameterName: String = "projectIds", projectIds: [String]) {
        self.parameterName = parameterName
        self.projectIds = projectIds
    }

    public var toParameters: [String: Any] {
        [parameterName: projectIds]
    }
}

/// 사유를 쿼리로 받는 DELETE (`DELETE .../members/{memberId}`·`.../applications/{id}`).
public struct ProjectReasonQueryDTO: Encodable, Equatable {
    public let reason: String?

    public init(reason: String?) {
        self.reason = reason
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        params["reason"] = reason
        return params
    }
}

/// 내 지원 내역 (`GET /me/applications`).
public struct ProjectMyApplicationsQueryDTO: Encodable, Equatable {
    public let gisuId: String
    public let status: String?

    public init(gisuId: String, status: ProjectApplicationStatus?) {
        self.gisuId = gisuId
        self.status = status?.rawValue
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = ["gisuId": gisuId]
        params["status"] = status
        return params
    }
}

/// 지원서 목록 필터 (`GET /applications`·`GET /{projectId}/applications`).
///
/// 단건 조회에서는 `projectIds` 를 비워 둔다 — 빈 배열은 쿼리에서 빠진다.
public struct ProjectApplicationsQueryDTO: Encodable, Equatable {
    public let projectIds: [String]
    public let matchingRoundId: String?
    public let part: String?
    public let status: String?

    public init(projectIds: [String] = [], filter: ProjectApplicationFilter) {
        self.projectIds = projectIds
        self.matchingRoundId = filter.matchingRoundId
        self.part = filter.part?.apiValue
        self.status = filter.status?.rawValue
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        if !projectIds.isEmpty { params["projectIds"] = projectIds }
        params["matchingRoundId"] = matchingRoundId
        params["part"] = part
        params["status"] = status
        return params
    }
}

/// 지원 통계 (`GET /statistics`). 서버는 둘 중 **하나만** 받는다.
public struct ProjectStatisticsQueryDTO: Encodable, Equatable {
    public let projectIds: [String]
    public let chapterId: String?

    public init(projectIds: [String]) {
        self.projectIds = projectIds
        self.chapterId = nil
    }

    public init(chapterId: String) {
        self.projectIds = []
        self.chapterId = chapterId
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        if !projectIds.isEmpty { params["projectIds"] = projectIds }
        params["chapterId"] = chapterId
        return params
    }
}

/// 지부 하나로 거르는 조회 (`GET /statistics/matchings`).
public struct ProjectChapterQueryDTO: Encodable, Equatable {
    public let chapterId: String

    public init(chapterId: String) {
        self.chapterId = chapterId
    }

    public var toParameters: [String: Any] {
        ["chapterId": chapterId]
    }
}

/// 매칭 차수 목록 (`GET /api/v1/project/matching-rounds`). 둘 다 선택.
public struct ProjectMatchingRoundQueryDTO: Encodable, Equatable {
    public let chapterId: String?
    /// UTC ISO 8601.
    public let time: String?

    public init(chapterId: String?, time: Date?) {
        self.chapterId = chapterId
        self.time = time.map(ServerDateTimeConverter.toUTCDateTimeString)
    }

    public var toParameters: [String: Any] {
        var params: [String: Any] = [:]
        params["chapterId"] = chapterId
        params["time"] = time
        return params
    }
}
