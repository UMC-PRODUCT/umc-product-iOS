//
//  StudyRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

protocol StudyRepositoryProtocol {
    /// 커리큘럼 화면에서 사용하는 데이터(진행률 + 미션 목록)를 가져옵니다.
    func fetchCurriculumData() async throws -> CurriculumData

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
    ///   - missionId: 제출할 챌린저 워크북 ID
    ///   - type: 미션 제출 타입 (링크 또는 체크)
    ///   - link: 제출 링크 (타입이 링크인 경우 필수)
    /// - Throws: 네트워크 오류, 파싱 오류, 또는 유효성 검증 오류
    func submitMission(
        missionId: Int,
        type: MissionSubmissionType,
        link: String?
    ) async throws

    // MARK: - 운영진 스터디 관리

    /// 스터디원 목록을 가져옵니다.
    /// - Returns: 스터디원 모델 배열
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchStudyMembers() async throws -> [StudyMemberItem]

    /// 스터디 그룹 목록을 가져옵니다.
    /// - Returns: 스터디 그룹 모델 배열
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchStudyGroups() async throws -> [StudyGroupItem]

    /// 스터디 주차 목록을 가져옵니다.
    /// - Returns: 주차 번호 배열
    /// - Throws: 네트워크 오류 또는 파싱 오류
    func fetchWeeks() async throws -> [Int]
}
