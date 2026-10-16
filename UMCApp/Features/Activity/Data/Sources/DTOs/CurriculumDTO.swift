//
//  CurriculumDTO.swift
//  ActivityData
//
//  Created by jaewon Lee on 6/7/26.
//

import Foundation
import ActivityDomain
import UMCFoundation

// MARK: - CurriculumDTO

/// 파트별 커리큘럼 조회 응답 DTO
///
/// `GET /api/v2/curriculums/overview?gisuId={ID}&part={PART}&weekNo={N}`
///
/// 서버 식별자(`curriculumId`)는 `String`, 주차 목록은 `WeeklyCurriculumDTO` 배열로 디코딩한다.
struct CurriculumDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    let curriculumId: String
    let title: String
    let weeks: [WeeklyCurriculumDTO]

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case curriculumId
        case title
        case weeks
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        curriculumId = container.decodeFlexibleStringOrNil(forKey: .curriculumId) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        weeks = try container.decodeIfPresent([WeeklyCurriculumDTO].self, forKey: .weeks) ?? []
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(curriculumId, forKey: .curriculumId)
        try container.encode(title, forKey: .title)
        try container.encode(weeks, forKey: .weeks)
    }
}

// MARK: - WeeklyCurriculumDTO

/// 주차 커리큘럼 항목 DTO
struct WeeklyCurriculumDTO: Codable, Sendable, Equatable {

    // MARK: - Property

    let weeklyCurriculumId: String
    let weekNo: String
    let title: String
    let startsAt: String
    let endsAt: String
    let isExtra: Bool

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case weeklyCurriculumId
        case weekNo
        case title
        case startsAt
        case endsAt
        case isExtra
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        weeklyCurriculumId =
            container.decodeFlexibleStringOrNil(forKey: .weeklyCurriculumId) ?? ""
        weekNo = container.decodeFlexibleStringOrNil(forKey: .weekNo) ?? "0"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        startsAt = try container.decodeIfPresent(String.self, forKey: .startsAt) ?? ""
        endsAt = try container.decodeIfPresent(String.self, forKey: .endsAt) ?? ""
        isExtra = try container.decodeBoolFlexibleIfPresent(forKey: .isExtra) ?? false
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(weeklyCurriculumId, forKey: .weeklyCurriculumId)
        try container.encode(weekNo, forKey: .weekNo)
        try container.encode(title, forKey: .title)
        try container.encode(startsAt, forKey: .startsAt)
        try container.encode(endsAt, forKey: .endsAt)
        try container.encode(isExtra, forKey: .isExtra)
    }
}

// MARK: - CurriculumDTO + toDomain

extension CurriculumDTO {

    func toCurriculumHeader(part: String) -> CurriculumHeaderModel {
        let partType = UMCPartType(apiValue: part)
        return CurriculumHeaderModel(
            partType: partType,
            partName: "\(partType?.name ?? part) PART CURRICULUM",
            curriculumTitle: title
        )
    }

    func toMissionCards(platform: String) -> [MissionCardModel] {
        weeks
            .map { $0.toMissionCard(platform: platform) }
            .sorted { (Int($0.week) ?? 0) < (Int($1.week) ?? 0) }
    }
}

// MARK: - WeeklyCurriculumDTO + Mapping

extension WeeklyCurriculumDTO {

    func toMissionCard(platform: String) -> MissionCardModel {
        MissionCardModel(
            week: weekNo,
            platform: platform,
            title: title,
            missionTitle: title,
            isExtra: isExtra
        )
    }
}
