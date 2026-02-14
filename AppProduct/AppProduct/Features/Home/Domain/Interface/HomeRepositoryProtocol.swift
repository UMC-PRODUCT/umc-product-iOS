//
//  HomeRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation

/// Home 데이터 접근 Repository Protocol
protocol HomeRepositoryProtocol: Sendable {

    /// 내 프로필 조회 (기수 카드 + 역할 정보)
    /// - Returns: 기수 카드용 데이터 + 역할별 (challengerId, gisuId) 매핑
    func getMyProfile() async throws -> HomeProfileResult

    /// 월별 내 일정 조회
    /// - Parameters:
    ///   - year: 연도 (예: 2026)
    ///   - month: 월 (1~12)
    /// - Returns: 날짜별로 그룹핑된 일정 딕셔너리
    func getSchedules(
        year: Int, month: Int
    ) async throws -> [Date: [ScheduleData]]

    /// 최근 공지 조회
    /// - Parameter query: 공지 목록 요청 파라미터
    /// - Returns: 최근 공지 데이터 목록
    func getRecentNotices(
        query: NoticeListRequestDTO
    ) async throws -> [RecentNoticeData]

    /// FCM 토큰 등록/갱신
    /// - Parameters:
    ///   - challengerId: 챌린저 ID
    ///   - fcmToken: Firebase Cloud Messaging 토큰
    func registerFCMToken(
        challengerId: Int,
        fcmToken: String
    ) async throws
}
