//
//  AvailableScheduleDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/17/26.
//

import Foundation

/// 출석 가능 일정 Response DTO
///
/// `GET /api/v1/attendances/available`
struct AvailableScheduleDTO: Codable, Sendable, Equatable {
    let scheduleId: Int
    let scheduleName: String
    let tags: [String]
    let startTime: String
    let endTime: String
    let sheetId: Int
    let recordId: Int?
    let status: String
    let statusDisplay: String
    let locationVerified: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scheduleName = try container.decode(String.self, forKey: .scheduleName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        status = try container.decode(String.self, forKey: .status)
        statusDisplay = try container.decode(String.self, forKey: .statusDisplay)
        locationVerified = try container.decodeIfPresent(Bool.self, forKey: .locationVerified)

        // 서버가 ID를 String으로 반환하는 경우 대응
        if let intId = try? container.decode(Int.self, forKey: .scheduleId) {
            scheduleId = intId
        } else {
            let strId = try container.decode(String.self, forKey: .scheduleId)
            scheduleId = Int(strId) ?? 0
        }
        if let intId = try? container.decode(Int.self, forKey: .sheetId) {
            sheetId = intId
        } else {
            let strId = try container.decode(String.self, forKey: .sheetId)
            sheetId = Int(strId) ?? 0
        }
        if let intId = try? container.decode(Int.self, forKey: .recordId) {
            recordId = intId
        } else if let strId = try? container.decode(String.self, forKey: .recordId) {
            recordId = Int(strId)
        } else {
            recordId = nil
        }
    }
}

// MARK: - toDomain

extension AvailableScheduleDTO {

    /// DTO → AvailableAttendanceSchedule Domain 모델 변환
    func toDomain() -> AvailableAttendanceSchedule {
        AvailableAttendanceSchedule(
            scheduleId: scheduleId,
            scheduleName: scheduleName,
            tags: tags,
            startTime: startTime,
            endTime: endTime,
            sheetId: sheetId,
            recordId: recordId,
            status: AttendanceStatus(serverStatus: status),
            statusDisplay: statusDisplay,
            locationVerified: locationVerified ?? false
        )
    }
}
