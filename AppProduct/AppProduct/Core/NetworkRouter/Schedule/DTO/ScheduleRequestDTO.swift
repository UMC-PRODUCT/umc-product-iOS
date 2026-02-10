
//
//  ScheduleRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Create Schedule

/// 일정 생성 요청 DTO
///
/// `POST /api/v1/schedules` 요청 Body
struct CreateScheduleRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let description: String
    let participantMemberIds: [Int]
    let tags: [String]
}

// MARK: - Update Schedule

/// 일정 수정 요청 DTO
///
/// `PATCH /api/v1/schedules/{scheduleId}` 요청 Body
struct UpdateScheduleRequestDTO: Encodable {
    let name: String?
    let startsAt: String?
    let endsAt: String?
    let isAllDay: Bool?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let tags: [String]?
}

// MARK: - Update Schedule Location

/// 일정 위치 수정 요청 DTO
///
/// `PATCH /api/v1/schedules/{scheduleId}/location` 요청 Body
struct UpdateScheduleLocationRequestDTO: Encodable {
    let locationName: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Create Schedule With Attendance

/// 일정 + 출석부 통합 생성 요청 DTO
///
/// `POST /api/v1/schedules/with-attendance` 요청 Body
struct CreateScheduleWithAttendanceRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let description: String
    let participantMemberIds: [Int]
    let tags: [String]
    /// 기수 ID
    let gisuId: Int
    /// 승인 필요 여부
    let requiresApproval: Bool
}

// MARK: - Create Study Group Schedule

/// 스터디 그룹 일정 생성 요청 DTO
///
/// `POST /api/v1/schedules/study-group` 요청 Body
struct CreateStudyGroupScheduleRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let description: String
    let tags: [String]
    /// 스터디 그룹 ID
    let studyGroupId: Int
    /// 기수 ID
    let gisuId: Int
    /// 승인 필요 여부
    let requiresApproval: Bool
}
