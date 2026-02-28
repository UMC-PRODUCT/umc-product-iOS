//
//  UpdateScheduleRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/13/26.
//

import Foundation

/// 홈 일정 수정 Request DTO
///
/// PATCH API 특성상 변경이 필요한 필드만 부분 전송할 수 있도록 Optional 필드를 사용합니다.
struct UpdateScheduleRequestDTO: Encodable {
    // MARK: - Property

    let name: String?
    let startsAt: Date?
    let endsAt: Date?
    let isAllDay: Bool?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let tags: [ScheduleIconCategory]?
    let participantMemberIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case name, startsAt, endsAt, isAllDay, locationName
        case latitude, longitude, description, tags, participantMemberIds
    }

    // MARK: - Function

    /// Optional 값만 인코딩하여 PATCH 요청 바디를 구성합니다.
    /// - Parameter encoder: JSON Encoder
    /// - Throws: 인코딩 실패 시 에러
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(isAllDay, forKey: .isAllDay)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(participantMemberIds, forKey: .participantMemberIds)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let startsAt {
            try container.encode(formatter.string(from: startsAt), forKey: .startsAt)
        }
        if let endsAt {
            try container.encode(formatter.string(from: endsAt), forKey: .endsAt)
        }
    }
}
