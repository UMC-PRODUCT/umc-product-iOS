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
        let profile = try apiResponse.unwrap()
        let seasonTypes = try await makeSeasonTypes(profile: profile)
        return profile.toHomeProfileResult(seasonTypes: seasonTypes)
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

    /// 일정 상세를 조회합니다.
    func getScheduleDetail(scheduleId: Int) async throws -> ScheduleDetailData {
        let response = try await adapter.request(
            HomeRouter.getScheduleDetail(scheduleId: scheduleId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<ScheduleDetailDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toScheduleDetailData()
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
        fcmToken: String
    ) async throws {
        let response = try await adapter.request(
            HomeRouter.putFCMToken(
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

// MARK: - Private Helpers

private extension HomeRepository {
    func makeSeasonTypes(profile: MyProfileResponseDTO) async throws -> [SeasonType] {
        let generations = Set(profile.roles.map(\.gisu)).sorted()
        let gisuIds = Set(profile.roles.map(\.gisuId)).filter { $0 > 0 }

        guard !gisuIds.isEmpty else {
            return [
                .days(0),
                .gens(generations)
            ]
        }

        var totalDays = 0
        try await withThrowingTaskGroup(of: Int.self) { group in
            for gisuId in gisuIds {
                group.addTask {
                    try await self.fetchActivityDays(gisuId: gisuId)
                }
            }

            for try await days in group {
                totalDays += days
            }
        }

        return [
            .days(max(totalDays, 0)),
            .gens(generations)
        ]
    }

    func fetchActivityDays(gisuId: Int) async throws -> Int {
        let response = try await adapter.request(
            HomeRouter.getGisuDetail(gisuId: gisuId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<GisuDetailDTO>.self,
            from: response.data
        )
        let gisuDetail = try apiResponse.unwrap()

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: gisuDetail.startAt)
        let endSource = gisuDetail.isActive ? Date() : gisuDetail.endAt
        let end = calendar.startOfDay(for: endSource)

        return max(calendar.dateComponents([.day], from: start, to: end).day ?? 0, 0)
    }
}
