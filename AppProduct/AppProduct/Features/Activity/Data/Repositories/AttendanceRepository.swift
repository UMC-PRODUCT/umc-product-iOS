//
//  AttendanceRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation
import Moya

/// 출석체크 Repository 구현체
///
/// `MoyaNetworkAdapter`를 통해 출석 관련 API를 호출하고
/// DTO → Domain 변환을 수행합니다.
final class AttendanceRepository: ChallengerAttendanceRepositoryProtocol,
                                   OperatorAttendanceRepositoryProtocol,
                                   @unchecked Sendable {

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

    // MARK: - 조회

    func getAttendanceDetail(
        recordId: Int
    ) async throws -> AttendanceRecord {
        let response = try await adapter.request(
            AttendanceRouter.getDetail(recordId: recordId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<AttendanceDetailDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }

    func getPendingAttendances(
        scheduleId: Int
    ) async throws -> [PendingAttendanceRecord] {
        let response = try await adapter.request(
            AttendanceRouter.getPending(scheduleId: scheduleId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<[PendingAttendanceDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    func getMyHistory() async throws -> [AttendanceHistoryItem] {
        let response = try await adapter.request(
            AttendanceRouter.getMyHistory
        )
        let apiResponse = try decoder.decode(
            APIResponse<[AttendanceHistoryItemDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    func getChallengerHistory(
        challengerId: Int
    ) async throws -> [AttendanceHistoryItem] {
        let response = try await adapter.request(
            AttendanceRouter.getChallengerHistory(
                challengerId: challengerId
            )
        )
        let apiResponse = try decoder.decode(
            APIResponse<[AttendanceHistoryItemDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    func getAvailableSchedules(
    ) async throws -> [AvailableAttendanceSchedule] {
        let response = try await adapter.request(
            AttendanceRouter.getAvailable
        )
        let apiResponse = try decoder.decode(
            APIResponse<[AvailableScheduleDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    // MARK: - 액션

    func approveAttendance(recordId: Int) async throws {
        let response = try await adapter.request(
            AttendanceRouter.approve(recordId: recordId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }

    func rejectAttendance(recordId: Int) async throws {
        let response = try await adapter.request(
            AttendanceRouter.reject(recordId: recordId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }

    func checkAttendance(
        request: AttendanceCheckRequestDTO
    ) async throws -> Int {
        let response = try await adapter.request(
            AttendanceRouter.check(body: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<Int>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }

    func submitReason(
        request: AttendanceReasonRequestDTO
    ) async throws -> Int {
        let response = try await adapter.request(
            AttendanceRouter.submitReason(body: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<Int>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
}
