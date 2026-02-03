//
//  StudyRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

protocol StudyRepositoryProtocol {
    /// 커리큘럼 진행률 정보를 가져옵니다.
    /// - Returns: 커리큘럼 진행률 모델
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchCurriculumProgress() async throws -> CurriculumProgressModel

    /// 미션 목록을 가져옵니다.
    /// - Returns: 미션 카드 모델 배열
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchMissions() async throws -> [MissionCardModel]

    /// 미션을 제출합니다.
    /// - Parameters:
    ///   - missionId: 제출할 미션의 고유 ID
    ///   - type: 미션 제출 타입 (링크 또는 체크)
    ///   - link: 제출 링크 (타입이 링크인 경우 필수)
    /// - Returns: 업데이트된 미션 카드 모델
    /// - Throws: 네트워크 오류, 파싱 오류, 또는 유효성 검증 오류
    func submitMission(
        missionId: UUID,
        type: MissionSubmissionType,
        link: String?
    ) async throws -> MissionCardModel
}
