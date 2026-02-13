//
//  ScheduleRepositoryProtocol.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 일정 생성/관리 데이터 접근 Repository Protocol
///
/// HomeRepositoryProtocol에서 일정 생성 책임을 분리하여
/// 단일 책임 원칙(SRP)을 강화한 Repository입니다.
///
/// - SeeAlso: ``ScheduleRepository``, ``GenerateScheduleUseCase``
protocol ScheduleRepositoryProtocol: Sendable {

    /// 출석 포함 일정을 생성합니다.
    ///
    /// - Parameter schedule: 일정 생성 요청 DTO (제목, 날짜, 장소, 참여자 등)
    /// - Throws: 서버 에러 또는 네트워크 에러
    func generateSchedule(
        schedule: GenerateScheduleRequetDTO
    ) async throws
}
