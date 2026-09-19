//
//  ProjectMatchingRoundRepository.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork
import UMCFoundation
import ProjectDomain

public final class ProjectMatchingRoundRepository:
    ProjectMatchingRoundRepositoryProtocol,
    @unchecked Sendable {

    // MARK: - Property

    private let adapter: any ProjectNetworkRequesting
    private let decoder: JSONDecoder

    // MARK: - Init

    public convenience init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.init(networkRequesting: adapter, decoder: decoder)
    }

    /// 테스트 seam — 가짜 네트워크를 주입해 응답 매핑을 검증한다.
    init(networkRequesting: any ProjectNetworkRequesting, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = networkRequesting
        self.decoder = decoder
    }

    // MARK: - Function

    public func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound] {
        let rounds: [ProjectMatchingRoundResponseDTO] = try await adapter.requestResult(
            ProjectMatchingRoundRouter.getMatchingRounds(
                query: ProjectMatchingRoundQueryDTO(chapterId: chapterId, time: time)
            ),
            decoder: decoder
        )
        return rounds.map { $0.toDomain() }
    }

    public func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String {
        let created: ProjectMatchingRoundCreateResponseDTO = try await adapter.requestResult(
            ProjectMatchingRoundRouter.createMatchingRound(
                body: try CreateProjectMatchingRoundRequestDTO(draft: draft)
            ),
            decoder: decoder
        )
        return created.matchingRoundId
    }

    public func updateMatchingRound(
        matchingRoundId: String,
        update: ProjectMatchingRoundUpdate
    ) async throws {
        try await adapter.requestSuccess(
            ProjectMatchingRoundRouter.updateMatchingRound(
                matchingRoundId: matchingRoundId,
                body: UpdateProjectMatchingRoundRequestDTO(update: update)
            ),
            decoder: decoder
        )
    }

    public func deleteMatchingRound(matchingRoundId: String) async throws {
        try await adapter.requestSuccess(
            ProjectMatchingRoundRouter.deleteMatchingRound(matchingRoundId: matchingRoundId),
            decoder: decoder
        )
    }

    public func autoDecide(matchingRoundId: String) async throws {
        try await adapter.requestSuccess(
            ProjectMatchingRoundRouter.autoDecide(matchingRoundId: matchingRoundId),
            decoder: decoder
        )
    }
}
