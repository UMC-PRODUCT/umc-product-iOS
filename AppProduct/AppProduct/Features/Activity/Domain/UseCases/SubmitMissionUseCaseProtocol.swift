//
//  SubmitMissionUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

// MARK: - Protocol

protocol SubmitMissionUseCaseProtocol {
    /// 미션 제출
    /// - Parameters:
    ///   - missionId: 미션 ID
    ///   - type: 제출 타입 (링크 또는 완료만)
    ///   - link: 링크 URL (링크 타입일 경우)
    /// - Returns: 상태가 업데이트된 미션 모델
    func execute(missionId: UUID, type: MissionSubmissionType, link: String?) async throws -> MissionCardModel
}
