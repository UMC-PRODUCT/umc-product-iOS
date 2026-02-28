//
//  ScheduleLocationUpdateRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 출석 일정 위치 변경 요청 DTO
///
/// `PATCH /api/v1/schedules/{scheduleId}/location`
struct ScheduleLocationUpdateRequestDTO: Codable, Sendable, Equatable {
    let locationName: String
    let latitude: Double
    let longitude: Double
}
