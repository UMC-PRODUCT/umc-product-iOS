//
//  GisuDetailDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 기수 상세 조회 Response DTO
///
/// `GET /api/v1/gisu/{gisuId}`
struct GisuDetailDTO: Codable {
    let gisuId: Int
    let generation: Int
    let gisu: Int
    let startAt: Date
    let endAt: Date
    let isActive: Bool

    private enum CodingKeys: String, CodingKey {
        case gisuId
        case generation
        case gisu
        case startAt
        case endAt
        case isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try container.decodeIntFlexibleIfPresent(forKey: .gisuId) ?? 0
        generation = try container.decodeIntFlexibleIfPresent(forKey: .generation) ?? 0
        gisu = try container.decodeIntFlexibleIfPresent(forKey: .gisu) ?? 0

        let startAtString = try container.decodeIfPresent(String.self, forKey: .startAt) ?? ""
        let endAtString = try container.decodeIfPresent(String.self, forKey: .endAt) ?? ""
        startAt = Self.parseISODate(startAtString) ?? .distantPast
        endAt = Self.parseISODate(endAtString) ?? .distantPast

        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
    }

    private static func parseISODate(_ raw: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let internetDateTimeFormatter = ISO8601DateFormatter()
        internetDateTimeFormatter.formatOptions = [.withInternetDateTime]

        return fractionalFormatter.date(from: raw) ?? internetDateTimeFormatter.date(from: raw)
    }
}

private extension KeyedDecodingContainer {
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key),
           let intValue = Int(value) {
            return intValue
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value)
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }
}
