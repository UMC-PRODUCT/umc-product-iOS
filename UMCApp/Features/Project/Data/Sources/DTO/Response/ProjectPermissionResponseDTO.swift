//
//  ProjectPermissionResponseDTO.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import UMCFoundation
import ProjectDomain

/// `GET /api/v1/projects/permissions` 응답 (서버 `ProjectPermissionsResponse`).
public struct ProjectPermissionsResponseDTO: Codable {
    let projects: [ProjectPermissionResponseDTO]

    private enum CodingKeys: String, CodingKey {
        case projects
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projects = try container.decodeIfPresent(
            [ProjectPermissionResponseDTO].self,
            forKey: .projects
        ) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projects, forKey: .projects)
    }

    public func toDomain() -> [ProjectPermission] {
        projects.map { $0.toDomain() }
    }
}

/// 권한 한 칸 (서버 `ProjectPermissionCapabilityInfo`).
public struct ProjectCapabilityDTO: Codable {
    let allowed: Bool
    let reasonCode: String?
    let reason: String?

    private enum CodingKeys: String, CodingKey {
        case allowed, reasonCode, reason
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        allowed = try container.decodeBoolFlexibleIfPresent(forKey: .allowed) ?? false
        reasonCode = try container.decodeIfPresent(String.self, forKey: .reasonCode)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(allowed, forKey: .allowed)
        try container.encodeIfPresent(reasonCode, forKey: .reasonCode)
        try container.encodeIfPresent(reason, forKey: .reason)
    }

    public func toDomain() -> ProjectCapability {
        ProjectCapability(allowed: allowed, reasonCode: reasonCode, reason: reason)
    }
}

/// 프로젝트 하나에 대한 권한 (서버 `ProjectPermissionResponse`).
///
/// 묶음(`applicationForm`·`status` 등)은 칸 이름을 키로 한 딕셔너리로 받는다. 칸이 빠지면
/// ``ProjectCapability/denied`` 로 채운다 — 모르는 권한을 허용으로 해석하지 않는다.
public struct ProjectPermissionResponseDTO: Codable {
    typealias CapabilityGroup = [String: ProjectCapabilityDTO]

    let projectId: String
    let exists: Bool
    let canEditInfo: ProjectCapabilityDTO?
    let canTransferOwnership: ProjectCapabilityDTO?
    let canDelete: ProjectCapabilityDTO?
    let applicationForm: CapabilityGroup
    let partQuota: CapabilityGroup
    let status: CapabilityGroup
    let application: CapabilityGroup
    let member: CapabilityGroup
    let statistics: CapabilityGroup

    private enum CodingKeys: String, CodingKey {
        case projectId, exists, canEditInfo, canTransferOwnership, canDelete
        case applicationForm, partQuota, status, application, member, statistics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try container.decodeFlexibleString(forKey: .projectId)
        exists = try container.decodeBoolFlexibleIfPresent(forKey: .exists) ?? false
        canEditInfo = try container.decodeIfPresent(
            ProjectCapabilityDTO.self,
            forKey: .canEditInfo
        )
        canTransferOwnership = try container.decodeIfPresent(
            ProjectCapabilityDTO.self,
            forKey: .canTransferOwnership
        )
        canDelete = try container.decodeIfPresent(ProjectCapabilityDTO.self, forKey: .canDelete)
        func group(_ key: CodingKeys) throws -> CapabilityGroup {
            try container.decodeIfPresent(CapabilityGroup.self, forKey: key) ?? [:]
        }
        applicationForm = try group(.applicationForm)
        partQuota = try group(.partQuota)
        status = try group(.status)
        application = try group(.application)
        member = try group(.member)
        statistics = try group(.statistics)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(exists, forKey: .exists)
        try container.encodeIfPresent(canEditInfo, forKey: .canEditInfo)
        try container.encodeIfPresent(canTransferOwnership, forKey: .canTransferOwnership)
        try container.encodeIfPresent(canDelete, forKey: .canDelete)
        try container.encode(applicationForm, forKey: .applicationForm)
        try container.encode(partQuota, forKey: .partQuota)
        try container.encode(status, forKey: .status)
        try container.encode(application, forKey: .application)
        try container.encode(member, forKey: .member)
        try container.encode(statistics, forKey: .statistics)
    }

    public func toDomain() -> ProjectPermission {
        func capability(_ group: CapabilityGroup, _ name: String) -> ProjectCapability {
            group[name]?.toDomain() ?? .denied
        }
        return ProjectPermission(
            projectId: projectId,
            exists: exists,
            canEditInfo: canEditInfo?.toDomain() ?? .denied,
            canTransferOwnership: canTransferOwnership?.toDomain() ?? .denied,
            canDelete: canDelete?.toDomain() ?? .denied,
            applicationForm: .init(
                canRead: capability(applicationForm, "canRead"),
                canCreate: capability(applicationForm, "canCreate"),
                canEdit: capability(applicationForm, "canEdit"),
                canPublish: capability(applicationForm, "canPublish"),
                canDelete: capability(applicationForm, "canDelete")
            ),
            partQuota: .init(canEdit: capability(partQuota, "canEdit")),
            status: .init(
                canRequestReview: capability(status, "canRequestReview"),
                canPublish: capability(status, "canPublish"),
                canComplete: capability(status, "canComplete"),
                canAbort: capability(status, "canAbort")
            ),
            application: .init(
                canCreate: capability(application, "canCreate"),
                canReadList: capability(application, "canReadList"),
                canDecide: capability(application, "canDecide")
            ),
            member: .init(
                canRead: capability(member, "canRead"),
                canCreate: capability(member, "canCreate"),
                canDelete: capability(member, "canDelete")
            ),
            statistics: .init(canRead: capability(statistics, "canRead"))
        )
    }
}
