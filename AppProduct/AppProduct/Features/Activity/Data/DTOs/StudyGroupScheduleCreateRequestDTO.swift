//
//  StudyGroupScheduleCreateRequestDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/24/26.
//

import Foundation

/// 스터디 그룹 일정 생성 Request DTO
///
/// `POST /api/v1/schedules/study-group`
struct StudyGroupScheduleCreateRequestDTO: Encodable {
    let name: String
    let startsAt: Date
    let endsAt: Date
    let isAllDay: Bool
    let locationName: String
    let latitude: Double
    let longitude: Double
    let description: String
    let tags: [String]
    let studyGroupId: Int
    let gisuId: Int
    let requiresApproval: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case startsAt
        case endsAt
        case isAllDay
        case locationName
        case latitude
        case longitude
        case description
        case tags
        case studyGroupId
        case gisuId
        case requiresApproval
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isAllDay, forKey: .isAllDay)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(studyGroupId, forKey: .studyGroupId)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(requiresApproval, forKey: .requiresApproval)

        // Date → ISO 8601 문자열로 직접 인코딩 (서버가 밀리초 포함 포맷을 요구)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(
            formatter.string(from: startsAt),
            forKey: .startsAt
        )
        try container.encode(
            formatter.string(from: endsAt),
            forKey: .endsAt
        )
    }
}
