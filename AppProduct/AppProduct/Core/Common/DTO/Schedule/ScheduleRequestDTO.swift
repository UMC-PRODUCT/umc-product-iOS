
//
//  ScheduleRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation

// MARK: - Create Schedule

/// 일정 단독 생성 요청 DTO
///
/// `POST /api/v1/schedules` 요청 Body
struct CreateScheduleRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
}

// MARK: - Create Schedule With Attendance

/// 일정 + 출석부 통합 생성 요청 DTO
///
/// `POST /api/v1/schedules/with-attendance` 요청 Body
struct CreateScheduleWithAttendanceRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
    let attendanceStartTime: String
    let attendanceEndTime: String
    let lateThresholdMinutes: Int
    let requiresApproval: Bool
    let latitude: Double
    let longitude: Double
    let locationName: String
}

// MARK: - Create Study Group Schedule

/// 스터디 그룹 일정 생성 요청 DTO
///
/// `POST /api/v1/schedules/study-group` 요청 Body
struct CreateStudyGroupScheduleRequestDTO: Encodable {
    let studyGroupId: Int
    let name: String
    let startsAt: String
    let endsAt: String
}

// MARK: - Update Schedule

/// 일정 수정 요청 DTO
///
/// `PATCH /api/v1/schedules/{scheduleId}` 요청 Body
struct UpdateScheduleRequestDTO: Encodable {
    let name: String
    let startsAt: String
    let endsAt: String
}

// MARK: - Update Schedule Location

/// 일정 출석체크 위치 변경 요청 DTO
///
/// `PATCH /api/v1/schedules/{scheduleId}/location` 요청 Body
struct UpdateScheduleLocationRequestDTO: Encodable {
    let latitude: Double
    let longitude: Double
    let locationName: String
}
