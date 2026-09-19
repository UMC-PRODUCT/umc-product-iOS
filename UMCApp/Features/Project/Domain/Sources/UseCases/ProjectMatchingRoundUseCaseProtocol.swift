//
//  ProjectMatchingRoundUseCaseProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 매칭 차수 UseCase. 메서드 의미는 ``ProjectMatchingRoundRepositoryProtocol`` 과 같다.
public protocol ProjectMatchingRoundUseCaseProtocol: Sendable {
    func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound]
    func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String
    func updateMatchingRound(
        matchingRoundId: String,
        update: ProjectMatchingRoundUpdate
    ) async throws
    func deleteMatchingRound(matchingRoundId: String) async throws
    func autoDecide(matchingRoundId: String) async throws
}
