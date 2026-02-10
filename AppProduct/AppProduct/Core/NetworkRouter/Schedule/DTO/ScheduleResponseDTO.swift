
//
//  ScheduleResponseDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Schedule List Item

/// 일정 목록 아이템 응답 DTO
///
/// `GET /api/v1/schedules/my-list` 응답
struct ScheduleListItemResponseDTO: Decodable {
    let scheduleId: Int
    let name: String
    let startsAt: String
    let endsAt: String
    let status: String
    let dDay: Int
}

// MARK: - Helpers

/// 일정 목록 조회 쿼리 파라미터
struct ScheduleListQuery: Encodable {
    let year: Int
    let month: Int
    
    var toParameters: [String: Any] {
        [
            "year": year,
            "month": month
        ]
    }
}
