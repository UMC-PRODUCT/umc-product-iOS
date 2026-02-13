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

    func getMyProfile() async throws -> HomeProfileResult {
        let response = try await adapter.request(HomeRouter.getGen)
        let apiResponse = try decoder.decode(
            APIResponse<MyProfileResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toHomeProfileResult()
    }

    func getPenalty(challengerId: Int, gisuId: Int) async throws -> GenerationData {
        let response = try await adapter.request(
            HomeRouter.getPenalty(id: challengerId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<ChallengerMemberDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toGenerationData(gisuId: gisuId)
    }

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

}
