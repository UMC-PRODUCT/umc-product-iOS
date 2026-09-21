//
//  WorkbookUseCase.swift
//  ActivityDomain
//
//  Created by euijjang97 on 9/21/26.
//

import CoreDomain
import Foundation
import UMCFoundation

public struct WorkbookReviewScope: Sendable {
    public let gisuId: String
    public let schoolId: String
    public let mentorIds: [String]
    public init(gisuId: String, schoolId: String, mentorIds: [String]) {
        self.gisuId = gisuId
        self.schoolId = schoolId
        self.mentorIds = mentorIds
    }
}

public protocol WorkbookRepositoryProtocol: Sendable {
    func list() async throws -> [WorkbookListItem]
    func detail(id: String) async throws -> WorkbookDetail
    func reviewScope(groupId: String, memberId: String) async throws -> WorkbookReviewScope
    func mutate(_ mutation: WorkbookMutation) async throws
}

public protocol WorkbookUseCaseProtocol: Sendable {
    func list() async throws -> [WorkbookListItem]
    func detail(id: String) async throws -> WorkbookDetail
    func canReview(_ detail: ChallengerWorkbookDetail, profile: Profile) async throws -> Bool
    func mutate(_ mutation: WorkbookMutation) async throws
}

public struct WorkbookUseCase: WorkbookUseCaseProtocol {
    private let repository: any WorkbookRepositoryProtocol
    public init(repository: any WorkbookRepositoryProtocol) { self.repository = repository }
    public func list() async throws -> [WorkbookListItem] { try await repository.list() }
    public func detail(id: String) async throws -> WorkbookDetail {
        try await repository.detail(id: id)
    }
    public func mutate(_ mutation: WorkbookMutation) async throws {
        try await repository.mutate(mutation)
    }
    public func canReview(_ detail: ChallengerWorkbookDetail, profile: Profile) async throws
        -> Bool
    {
        if profile.roles.contains(where: { $0.roleType == .superAdmin }) { return true }
        guard let groupId = detail.receivedStudyGroupId else { return false }
        let scope = try await repository.reviewScope(groupId: groupId, memberId: detail.memberId)
        if scope.mentorIds.contains(profile.memberId) { return true }
        return !scope.gisuId.isEmpty && !scope.schoolId.isEmpty
            && profile.roles.contains {
                ($0.roleType == .schoolPresident || $0.roleType == .schoolVicePresident)
                    && $0.gisuId == scope.gisuId && $0.organizationId == scope.schoolId
                    && $0.organizationType == .school
            }
    }
}
