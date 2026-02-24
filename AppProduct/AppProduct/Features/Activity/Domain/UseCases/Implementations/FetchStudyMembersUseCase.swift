//
//  FetchStudyMembersUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

// MARK: - FetchStudyMembersUseCase

/// 운영진 스터디원 관리 데이터 조회 UseCase 구현체
final class FetchStudyMembersUseCase: FetchStudyMembersUseCaseProtocol {

    // MARK: - Property

    private let repository: StudyRepositoryProtocol

    // MARK: - Init

    init(repository: StudyRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func fetchMembers(
        week: Int,
        studyGroupId: Int?
    ) async throws -> [StudyMemberItem] {
        try await repository.fetchStudyMembers(
            week: week,
            studyGroupId: studyGroupId
        )
    }

    func fetchStudyGroups() async throws -> [StudyGroupItem] {
        try await repository.fetchStudyGroups()
    }

    func fetchStudyGroupDetails() async throws -> [StudyGroupInfo] {
        try await repository.fetchStudyGroupDetails()
    }

    func fetchStudyGroupDetailsPage(
        cursor: Int?,
        size: Int
    ) async throws -> StudyGroupDetailsPage {
        try await repository.fetchStudyGroupDetailsPage(
            cursor: cursor,
            size: size
        )
    }

    func fetchWeeks() async throws -> [Int] {
        try await repository.fetchWeeks()
    }

    func fetchWorkbookSubmissionURL(
        challengerWorkbookId: Int
    ) async throws -> String? {
        try await repository.fetchWorkbookSubmissionURL(
            challengerWorkbookId: challengerWorkbookId
        )
    }

    func reviewWorkbook(
        challengerWorkbookId: Int,
        isApproved: Bool,
        feedback: String
    ) async throws {
        try await repository.reviewWorkbook(
            challengerWorkbookId: challengerWorkbookId,
            isApproved: isApproved,
            feedback: feedback
        )
    }

    func selectBestWorkbook(
        challengerWorkbookId: Int,
        bestReason: String
    ) async throws {
        try await repository.selectBestWorkbook(
            challengerWorkbookId: challengerWorkbookId,
            bestReason: bestReason
        )
    }

    func createStudyGroup(
        name: String,
        part: UMCPartType,
        leaderId: Int,
        memberIds: [Int]
    ) async throws {
        try await repository.createStudyGroup(
            name: name,
            part: part,
            leaderId: leaderId,
            memberIds: memberIds
        )
    }

    func updateStudyGroupMembers(
        groupId: Int,
        challengerIds: [Int]
    ) async throws {
        try await repository.updateStudyGroupMembers(
            groupId: groupId,
            challengerIds: challengerIds
        )
    }

    func updateStudyGroup(
        groupId: Int,
        name: String,
        part: UMCPartType
    ) async throws {
        try await repository.updateStudyGroup(
            groupId: groupId,
            name: name,
            part: part
        )
    }

    func deleteStudyGroup(groupId: Int) async throws {
        try await repository.deleteStudyGroup(groupId: groupId)
    }

    func createStudyGroupSchedule(
        name: String,
        startsAt: Date,
        endsAt: Date,
        isAllDay: Bool,
        locationName: String,
        latitude: Double,
        longitude: Double,
        description: String,
        studyGroupId: Int,
        gisuId: Int,
        requiresApproval: Bool
    ) async throws {
        try await repository.createStudyGroupSchedule(
            name: name,
            startsAt: startsAt,
            endsAt: endsAt,
            isAllDay: isAllDay,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            description: description,
            studyGroupId: studyGroupId,
            gisuId: gisuId,
            requiresApproval: requiresApproval
        )
    }
}
