//
//  ProjectPermission.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 권한 한 칸 (서버 `ProjectPermissionCapabilityInfo`).
///
/// 거부되면 서버가 `reasonCode`(`ProjectPermissionReason` 이름, 예: `PERMISSION_DENIED`)와
/// 사람이 읽을 `reason` 을 같이 준다.
public struct ProjectCapability: Sendable, Equatable {
    public let allowed: Bool
    public let reasonCode: String?
    public let reason: String?

    public init(allowed: Bool, reasonCode: String? = nil, reason: String? = nil) {
        self.allowed = allowed
        self.reasonCode = reasonCode
        self.reason = reason
    }

    /// 응답에 칸이 빠졌을 때 쓰는 값 — 모르는 권한은 허용하지 않는다.
    public static let denied = ProjectCapability(allowed: false)
}

/// 프로젝트 하나에 대한 내 권한 (서버 `ProjectPermissionResponse`).
public struct ProjectPermission: Sendable, Equatable {
    public let projectId: String
    /// `false` 면 프로젝트가 없다 — 나머지 칸은 전부 거부로 온다.
    public let exists: Bool
    public let canEditInfo: ProjectCapability
    public let canTransferOwnership: ProjectCapability
    public let canDelete: ProjectCapability
    public let applicationForm: ApplicationForm
    public let partQuota: PartQuota
    public let status: Status
    public let application: Application
    public let member: Member
    public let statistics: Statistics

    public init(
        projectId: String,
        exists: Bool,
        canEditInfo: ProjectCapability,
        canTransferOwnership: ProjectCapability,
        canDelete: ProjectCapability,
        applicationForm: ApplicationForm,
        partQuota: PartQuota,
        status: Status,
        application: Application,
        member: Member,
        statistics: Statistics
    ) {
        self.projectId = projectId
        self.exists = exists
        self.canEditInfo = canEditInfo
        self.canTransferOwnership = canTransferOwnership
        self.canDelete = canDelete
        self.applicationForm = applicationForm
        self.partQuota = partQuota
        self.status = status
        self.application = application
        self.member = member
        self.statistics = statistics
    }

    /// 지원 폼 권한.
    public struct ApplicationForm: Sendable, Equatable {
        public let canRead: ProjectCapability
        public let canCreate: ProjectCapability
        public let canEdit: ProjectCapability
        public let canPublish: ProjectCapability
        public let canDelete: ProjectCapability

        public init(
            canRead: ProjectCapability,
            canCreate: ProjectCapability,
            canEdit: ProjectCapability,
            canPublish: ProjectCapability,
            canDelete: ProjectCapability
        ) {
            self.canRead = canRead
            self.canCreate = canCreate
            self.canEdit = canEdit
            self.canPublish = canPublish
            self.canDelete = canDelete
        }
    }

    /// 파트 TO 권한.
    public struct PartQuota: Sendable, Equatable {
        public let canEdit: ProjectCapability

        public init(canEdit: ProjectCapability) {
            self.canEdit = canEdit
        }
    }

    /// 상태 전이 권한.
    public struct Status: Sendable, Equatable {
        public let canRequestReview: ProjectCapability
        public let canPublish: ProjectCapability
        public let canComplete: ProjectCapability
        public let canAbort: ProjectCapability

        public init(
            canRequestReview: ProjectCapability,
            canPublish: ProjectCapability,
            canComplete: ProjectCapability,
            canAbort: ProjectCapability
        ) {
            self.canRequestReview = canRequestReview
            self.canPublish = canPublish
            self.canComplete = canComplete
            self.canAbort = canAbort
        }
    }

    /// 지원서 권한.
    public struct Application: Sendable, Equatable {
        public let canCreate: ProjectCapability
        public let canReadList: ProjectCapability
        public let canDecide: ProjectCapability

        public init(
            canCreate: ProjectCapability,
            canReadList: ProjectCapability,
            canDecide: ProjectCapability
        ) {
            self.canCreate = canCreate
            self.canReadList = canReadList
            self.canDecide = canDecide
        }
    }

    /// 팀원 권한.
    public struct Member: Sendable, Equatable {
        public let canRead: ProjectCapability
        public let canCreate: ProjectCapability
        public let canDelete: ProjectCapability

        public init(
            canRead: ProjectCapability,
            canCreate: ProjectCapability,
            canDelete: ProjectCapability
        ) {
            self.canRead = canRead
            self.canCreate = canCreate
            self.canDelete = canDelete
        }
    }

    /// 통계 권한.
    public struct Statistics: Sendable, Equatable {
        public let canRead: ProjectCapability

        public init(canRead: ProjectCapability) {
            self.canRead = canRead
        }
    }
}
