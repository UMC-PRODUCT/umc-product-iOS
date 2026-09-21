//
//  WorkbookProgressDTO.swift
//  ActivityData
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
import Foundation
import UMCFoundation

struct WorkbookProgressDTO: Codable {
    let weeks: [WorkbookProgressWeekDTO]
    enum CodingKeys: String, CodingKey { case weeks }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        weeks = try values.decode([WorkbookProgressWeekDTO].self, forKey: .weeks)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(weeks, forKey: .weeks)
    }
    func toDomain() -> [WorkbookListItem] {
        weeks.flatMap { week in
            week.originalWorkbooks.map {
                WorkbookListItem(
                    originalWorkbookId: $0.originalWorkbookId,
                    challengerWorkbookId: $0.challengerWorkbookId,
                    title: "\(week.curriculum.weekNo)주차 · \($0.title)",
                    endsAt: week.curriculum.parsedEndsAt
                )
            }
        }
    }
}

struct WorkbookProgressWeekDTO: Codable {
    let curriculum: WeeklyCurriculumDTO
    let originalWorkbooks: [WorkbookProgressItemDTO]
    enum CodingKeys: String, CodingKey { case originalWorkbooks }
    init(from decoder: Decoder) throws {
        curriculum = try WeeklyCurriculumDTO(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        originalWorkbooks = try values.decode(
            [WorkbookProgressItemDTO].self, forKey: .originalWorkbooks)
    }
    func encode(to encoder: Encoder) throws {
        try curriculum.encode(to: encoder)
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(originalWorkbooks, forKey: .originalWorkbooks)
    }
}

struct WorkbookProgressItemDTO: Codable {
    let originalWorkbookId: String
    let challengerWorkbookId: String?
    let title: String
    enum CodingKeys: String, CodingKey { case originalWorkbookId, challengerWorkbookId, title }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        originalWorkbookId = values.decodeFlexibleStringOrNil(forKey: .originalWorkbookId) ?? ""
        challengerWorkbookId = values.decodeFlexibleStringOrNil(forKey: .challengerWorkbookId)
        title = try values.decode(String.self, forKey: .title)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(originalWorkbookId, forKey: .originalWorkbookId)
        try values.encodeIfPresent(challengerWorkbookId, forKey: .challengerWorkbookId)
        try values.encode(title, forKey: .title)
    }
}
