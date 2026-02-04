//
//  SubmitMissionUseCase.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

// MARK: - SubmitMissionUseCase

/// 미션 제출 UseCase 구현체
final class SubmitMissionUseCase: SubmitMissionUseCaseProtocol {

    // MARK: - Property

    private let repository: StudyRepositoryProtocol

    // MARK: - Init

    init(repository: StudyRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Function

    func execute(
        missionId: UUID,
        type: MissionSubmissionType,
        link: String?
    ) async throws -> MissionCardModel {
        // 링크 타입일 경우 링크 입력 검증
        if type == .link {
            guard let link, !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DomainError.missionLinkRequired
            }
        }

        return try await repository.submitMission(
            missionId: missionId,
            type: type,
            link: link
        )
    }
}
