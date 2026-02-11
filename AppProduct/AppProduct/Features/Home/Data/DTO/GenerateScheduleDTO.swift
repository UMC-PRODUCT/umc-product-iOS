//
//  GenerateScheduleDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

struct GenerateScheduleDTO: Codable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.isAllDay = try container.decode(Bool.self, forKey: .isAllDay)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.description = try container.decode(String.self, forKey: .description)
        self.participantMemberIds = try container.decode([Int].self, forKey: .participantMemberIds)
        self.tags = try container.decode([ScheduleIconCategory].self, forKey: .tags)
        self.gisuId = try container.decode(Int.self, forKey: .gisuId)
        self.requiresApproval = try container.decode(Bool.self, forKey: .requiresApproval)

        let startsAtString = try container.decode(String.self, forKey: .startsAt)
        let endsAtString = try container.decode(String.self, forKey: .endsAt)

        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        if let starts = formatterWithFraction.date(from: startsAtString) ?? formatter.date(from: startsAtString) {
            self.startsAt = starts
        } else {
            throw DecodingError.dataCorruptedError(forKey: .startsAt,
                                                   in: container,
                                                   debugDescription: "Invalid ISO8601 date string for startsAt: \(startsAtString)")
        }

        if let ends = formatterWithFraction.date(from: endsAtString) ?? formatter.date(from: endsAtString) {
            self.endsAt = ends
        } else {
            throw DecodingError.dataCorruptedError(forKey: .endsAt,
                                                   in: container,
                                                   debugDescription: "Invalid ISO8601 date string for endsAt: \(endsAtString)")
        }
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
