//
//  ProjectMatchingRoundUseCase.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 지금은 저장소를 그대로 잇는다 — 운영진 화면 이슈(#1479)에서 로직이 붙는다.
public final class ProjectMatchingRoundUseCase: ProjectMatchingRoundUseCaseProtocol {

    // MARK: - Property

    private let repository: ProjectMatchingRoundRepositoryProtocol

    // MARK: - Init

    public init(repository: ProjectMatchingRoundRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    public func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound] {
        try await repository.fetchMatchingRounds(chapterId: chapterId, time: time)
    }

    public func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String {
        try await repository.createMatchingRound(draft)
    }

    public func updateMatchingRound(
        matchingRoundId: String,
        update: ProjectMatchingRoundUpdate
    ) async throws {
        try await repository.updateMatchingRound(matchingRoundId: matchingRoundId, update: update)
    }

    public func deleteMatchingRound(matchingRoundId: String) async throws {
        try await repository.deleteMatchingRound(matchingRoundId: matchingRoundId)
    }

    public func autoDecide(matchingRoundId: String) async throws {
        try await repository.autoDecide(matchingRoundId: matchingRoundId)
    }
}
