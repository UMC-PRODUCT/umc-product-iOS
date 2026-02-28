//
//  GenerateScheduleDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

/// 홈 일정 생성 Request DTO
struct GenerateScheduleRequetDTO: Encodable {
    let name: String
    let startsAt: Date
    let endsAt: Date
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let description: String
    let participantMemberIds: [Int]
    let tags: [ScheduleIconCategory]
    let gisuId: Int
    let requiresApproval: Bool

    init(name: String,
         startsAt: Date,
         endsAt: Date,
         isAllDay: Bool,
         locationName: String,
         latitude: Double,
         longitude: Double,
         description: String,
         participantMemberIds: [Int],
         tags: [ScheduleIconCategory],
         gisuId: Int,
         requiresApproval: Bool) {
        self.name = name
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.isAllDay = isAllDay
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.participantMemberIds = participantMemberIds
        self.tags = tags
        self.gisuId = gisuId
        self.requiresApproval = requiresApproval
    }

    enum CodingKeys: String, CodingKey {
        case name, startsAt, endsAt, isAllDay, locationName
        case latitude, longitude, description, participantMemberIds, tags
        case gisuId, requiresApproval
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(description, forKey: .description)
        try container.encode(participantMemberIds, forKey: .participantMemberIds)
        try container.encode(tags, forKey: .tags)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(requiresApproval, forKey: .requiresApproval)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startsAtString = formatter.string(from: startsAt)
        let endsAtString = formatter.string(from: endsAt)
        try container.encode(startsAtString, forKey: .startsAt)
        try container.encode(endsAtString, forKey: .endsAt)
    }
}
