//
//  ProjectMatchingRoundRepositoryProtocol.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 매칭 차수 저장소 (`/api/v1/project/matching-rounds`).
public protocol ProjectMatchingRoundRepositoryProtocol: Sendable {

    /// 매칭 차수 목록 (`GET /`). `time` 을 주면 그 시각에 진행 중인 차수만 — `chapterId` 가 필요하다.
    func fetchMatchingRounds(chapterId: String?, time: Date?) async throws
        -> [ProjectMatchingRound]

    /// 매칭 차수 생성 (`POST /`).
    /// - Returns: 새 매칭 차수 id.
    func createMatchingRound(_ draft: ProjectMatchingRoundDraft) async throws -> String

    /// 매칭 차수 수정 (`PATCH /{matchingRoundId}`).
    func updateMatchingRound(
        matchingRoundId: String,
        update: ProjectMatchingRoundUpdate
    ) async throws

    /// 매칭 차수 삭제 (`DELETE /{matchingRoundId}`).
    func deleteMatchingRound(matchingRoundId: String) async throws

    /// 결정 마감 후 미결정 지원서 자동 결정 (`POST /{matchingRoundId}/auto-decide`).
    func autoDecide(matchingRoundId: String) async throws
}
