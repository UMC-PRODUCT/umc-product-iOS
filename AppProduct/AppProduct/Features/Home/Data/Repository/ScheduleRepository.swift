//
//  ScheduleRepository.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
import Moya

/// Schedule Repository 구현체
///
/// `ScheduleRepositoryProtocol`을 구현하며,
/// `ScheduleRouter`를 통해 일정 관련 API를 호출합니다.
///
/// - SeeAlso: ``ScheduleRepositoryProtocol``, ``ScheduleRouter``
final class ScheduleRepository: ScheduleRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    /// Moya 기반 네트워크 어댑터
    private let adapter: MoyaNetworkAdapter

    /// JSON 디코더
    private let decoder: JSONDecoder

    // MARK: - Init

    /// - Parameters:
    ///   - adapter: API 요청을 처리할 네트워크 어댑터
    ///   - decoder: JSON 디코딩에 사용할 디코더 (기본값: JSONDecoder)
    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function

    func generateSchedule(
        schedule: GenerateScheduleRequetDTO
    ) async throws {
        let response = try await adapter.request(
            ScheduleRouter.postGenerateSchedule(schedule: schedule)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
}
