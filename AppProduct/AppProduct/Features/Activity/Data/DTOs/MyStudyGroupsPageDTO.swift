//
//  MyStudyGroupsPageDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 내 스터디 그룹 목록 페이지 DTO
///
/// `GET /api/v1/study-groups`
struct MyStudyGroupsPageDTO: Codable, Sendable, Equatable {
    let studyGroups: [StudyGroupNameItemDTO]
    let nextCursor: Int?
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case cursor
        case studyGroups
        case content
        case nextCursor
        case hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 서버가 cursor 래핑 포맷으로 응답하는 경우
        if let cursor = try container.decodeIfPresent(MyStudyGroupsCursorDTO.self, forKey: .cursor) {
            studyGroups = cursor.content
            nextCursor = cursor.nextCursor
            hasNext = cursor.hasNext
            return
        }

        // content 키를 직접 포함하는 flat 포맷인 경우
        if let content = try container.decodeIfPresent([StudyGroupNameItemDTO].self, forKey: .content) {
            studyGroups = content
            nextCursor = try container.decodeIntFlexibleIfPresent(forKey: .nextCursor)
            hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
            return
        }

        // studyGroups 키를 직접 포함하는 포맷 (최종 fallback)
        studyGroups = try container.decodeIfPresent([StudyGroupNameItemDTO].self, forKey: .studyGroups) ?? []
        nextCursor = try container.decodeIntFlexibleIfPresent(forKey: .nextCursor)
        hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(studyGroups, forKey: .studyGroups)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try container.encode(hasNext, forKey: .hasNext)
    }
}

private struct MyStudyGroupsCursorDTO: Codable, Sendable, Equatable {
    let content: [StudyGroupNameItemDTO]
    let nextCursor: Int?
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case content
        case nextCursor
        case hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([StudyGroupNameItemDTO].self, forKey: .content) ?? []
        nextCursor = try container.decodeIntFlexibleIfPresent(forKey: .nextCursor)
        hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(nextCursor, forKey: .nextCursor)
        try container.encode(hasNext, forKey: .hasNext)
    }
}

private extension KeyedDecodingContainer {
    /// Int, String, Double 형태로 인코딩된 값을 Int로 유연하게 디코딩합니다.
    ///
    /// - Parameter key: 디코딩할 CodingKey
    /// - Returns: 변환된 Int 값
    /// - Throws: 변환 불가 시 `DecodingError.typeMismatch`
    func decodeIntFlexible(forKey key: Key) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? decode(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return Int(doubleValue)
        }

        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected Int/String-number/Double for key '\(key.stringValue)'"
            )
        )
    }

    /// 키가 nil이거나 변환 불가한 경우 nil을 반환하는 `decodeIntFlexible`의 Optional 버전입니다.
    /// - Parameter key: 디코딩할 CodingKey
    /// - Returns: 변환된 Int 값, nil이면 nil
    func decodeIntFlexibleIfPresent(forKey key: Key) throws -> Int? {
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try? decodeIntFlexible(forKey: key)
    }

    /// Bool, Int(0/1), String("true"/"false") 형태로 인코딩된 값을 Bool로 유연하게 디코딩합니다.
    /// - Parameter key: 디코딩할 CodingKey
    /// - Returns: 변환된 Bool 값, 변환 불가 시 nil
    func decodeBoolFlexibleIfPresent(forKey key: Key) throws -> Bool? {
        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue != 0
        }
        if let stringValue = try? decode(String.self, forKey: key) {
            switch stringValue.lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }
}
