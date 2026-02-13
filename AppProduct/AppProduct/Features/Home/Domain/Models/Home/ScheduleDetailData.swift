//
//  ScheduleDetailData.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 일정 상세 도메인 모델
struct ScheduleDetailData: Equatable, Identifiable {
    // MARK: - Property

    var id: UUID = .init()
    let scheduleId: Int
    let name: String
    let description: String
    let tags: [String]
    let startsAt: Date
    let endsAt: Date
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let status: String
    let dDay: Int
    let requiresAttendanceApproval: Bool
}
