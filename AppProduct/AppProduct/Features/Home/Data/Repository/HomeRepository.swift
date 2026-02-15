//
//  HomeRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/12/26.
//

import Foundation
import Moya

/// Home Repository 구현체
final class HomeRepository: HomeRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function

    /// 내 프로필 조회 (기수 카드 + 역할 정보)
    func getMyProfile() async throws -> HomeProfileResult {
        let response = try await adapter.request(HomeRouter.getGen)
        let apiResponse = try decoder.decode(
            APIResponse<MyProfileResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toHomeProfileResult()
    }

    /// 월별 일정을 조회하고 날짜별로 그룹핑하여 반환합니다.
    func getSchedules(
        year: Int, month: Int
    ) async throws -> [Date: [ScheduleData]] {
        let response = try await adapter.request(
            HomeRouter.getSchedules(year: year, month: month)
        )
        let apiResponse = try decoder.decode(
            APIResponse<[HomeScheduleResponseDTO]>.self,
            from: response.data
        )
        let schedules = try apiResponse.unwrap().map {
            $0.toScheduleData()
        }
        let calendar = Calendar.current
        return Dictionary(grouping: schedules) {
            calendar.startOfDay(for: $0.startsAt)
        }
    }

    /// 최근 공지사항을 조회합니다 (최대 5개).
    func getRecentNotices(
        query: NoticeListRequestDTO
    ) async throws -> [RecentNoticeData] {
        let response = try await adapter.request(
            HomeRouter.getNoticeRecent(query: query)
        )
        let apiResponse = try decoder.decode(
            APIResponse<PageDTO<NoticeListResponseDTO>>.self,
            from: response.data
        )
        let page = try apiResponse.unwrap()
        return Array(page.content.prefix(5).map { $0.toRecentNoticeData() })
    }

    /// FCM 토큰을 서버에 등록/갱신합니다.
    func registerFCMToken(
        memberId: Int,
        fcmToken: String
    ) async throws {
        let response = try await adapter.request(
            HomeRouter.postFCMToken(
                memberId: memberId,
                request: RegisterFCMTokenRequestDTO(fcmToken: fcmToken)
            )
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }

}
