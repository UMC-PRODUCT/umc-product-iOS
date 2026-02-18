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
    ///   - missionId: 챌린저 워크북 ID
    ///   - type: 제출 타입 (링크 또는 완료만)
    ///   - link: 링크 URL (링크 타입일 경우)
    func execute(missionId: Int, type: MissionSubmissionType, link: String?) async throws
}
