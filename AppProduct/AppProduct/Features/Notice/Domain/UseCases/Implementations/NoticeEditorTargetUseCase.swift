//
//  NoticeEditorTargetUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

/// 공지 에디터 타겟(지부/학교) 조회 UseCase 구현체
final class NoticeEditorTargetUseCase: NoticeEditorTargetUseCaseProtocol {

    // MARK: - Property

    private let repository: NoticeEditorTargetRepositoryProtocol

    // MARK: - Init

    init(repository: NoticeEditorTargetRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - NoticeEditorTargetUseCaseProtocol

    func fetchAllBranches() async throws -> [NoticeTargetOption] {
        try await repository.fetchAllBranches()
    }

    func fetchBranches(gisuId: Int) async throws -> [NoticeTargetOption] {
        try await repository.fetchBranches(gisuId: gisuId)
    }

    func fetchBranchName(chapterId: Int) async throws -> String {
        try await repository.fetchBranchName(chapterId: chapterId)
    }

    func fetchAllSchools() async throws -> [NoticeTargetOption] {
        try await repository.fetchAllSchools()
    }

    func fetchSchools(gisuId: Int) async throws -> [NoticeTargetOption] {
        try await repository.fetchSchools(gisuId: gisuId)
    }

    func fetchSchools(inChapterId chapterId: Int, gisuId: Int) async throws -> [NoticeTargetOption] {
        try await repository.fetchSchools(inChapterId: chapterId, gisuId: gisuId)
    }
}
