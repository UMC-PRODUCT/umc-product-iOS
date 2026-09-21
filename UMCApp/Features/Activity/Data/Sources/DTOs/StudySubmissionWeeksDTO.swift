//
//  StudySubmissionWeeksDTO.swift
//
//  Created by euijjang97 on 9/21/26.
//

import Foundation

struct StudySubmissionWeeksQuery: Sendable {
    let studyGroupId: String?
    var gisuId: String? = nil

    var toParameters: [String: Any] {
        var parameters: [String: Any] = [:]
        if let studyGroupId { parameters["studyGroupId"] = studyGroupId }
        if let gisuId { parameters["gisuId"] = gisuId }
        return parameters
    }
}

struct StudySubmissionWeeksDTO: Codable {
    let weekNos: [String]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var values: [String] = []
        while !container.isAtEnd {
            let value: String
            if let string = try? container.decode(String.self) {
                value = string
            } else {
                let number = try container.decode(Decimal.self)
                value = NSDecimalNumber(decimal: number).stringValue
            }
            guard let week = Int64(value), week > 0 else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Expected a positive week number"
                )
            }
            values.append(String(week))
        }
        weekNos = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for weekNo in weekNos { try container.encode(weekNo) }
    }
}
