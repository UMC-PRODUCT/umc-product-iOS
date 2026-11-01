// Created by euijjang97 on 11/1/26.

import Foundation
import CoreDomain

/// 운영 화면에서 서버 식별자와 표시 데이터를 함께 보존합니다.
public struct AdminMember: Identifiable, Equatable {
    public let id: String
    public let member: MemberManagementItem
    public let gisuId: String
    public let schoolId: String
    public let generation: String

    public init(id: String, member: MemberManagementItem, gisuId: String,
                schoolId: String, generation: String) {
        self.id = id
        self.member = member
        self.gisuId = gisuId
        self.schoolId = schoolId
        self.generation = generation
    }
}

public struct AdminMemberPage: Equatable {
    public let members: [AdminMember]
    public let hasNext: Bool
    public init(members: [AdminMember], hasNext: Bool) {
        self.members = members
        self.hasNext = hasNext
    }
}

public struct MemberSearchFilter: Equatable, Sendable {
    public var keyword: String
    public var gisuId: String
    public var chapterId: String?
    public var schoolId: String?
    public var part: String?
    public init(keyword: String = "", gisuId: String = "", chapterId: String? = nil,
                schoolId: String? = nil, part: String? = nil) {
        self.keyword = keyword
        self.gisuId = gisuId
        self.chapterId = chapterId
        self.schoolId = schoolId
        self.part = part
    }
}

public struct MemberFilterOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let parentId: String?
    public let isActive: Bool
    public init(id: String, name: String, parentId: String? = nil, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.isActive = isActive
    }
}

public struct MemberOrganizationOptions: Equatable {
    public let chapters: [MemberFilterOption]
    public let schools: [MemberFilterOption]
    public init(chapters: [MemberFilterOption], schools: [MemberFilterOption]) {
        self.chapters = chapters
        self.schools = schools
    }
}

public struct MemberAdministrationAuthority: Equatable {
    public let roles: [ProfileRole]
    public let isSuperAdmin: Bool
    public init(roles: [ProfileRole], isSuperAdmin: Bool = false) {
        self.roles = roles
        self.isSuperAdmin = isSuperAdmin
    }
}

/// 챌린저 목록/스터디 초대와 분리된 운영진 검색·수정 계약입니다.
public protocol MemberAdministrationRepositoryProtocol {
    func search(filter: MemberSearchFilter, page: Int) async throws -> AdminMemberPage
    func fetchGenerations() async throws -> [MemberFilterOption]
    func fetchOrganizations(gisuId: String) async throws -> MemberOrganizationOptions
    func fetchAuthority() async throws -> MemberAdministrationAuthority
    func updatePointDescription(pointId: String, description: String) async throws
}
