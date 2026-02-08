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

    func fetchMembers() async throws -> [StudyMemberItem] {
        try await repository.fetchStudyMembers()
    }

    func fetchStudyGroups() async throws -> [StudyGroupItem] {
        try await repository.fetchStudyGroups()
    }

    func fetchWeeks() async throws -> [Int] {
        try await repository.fetchWeeks()
    }
}
