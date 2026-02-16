//
//  NoticeDetailContentDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

struct NoticeDetailVoteDTO: Codable {
    let voteId: String
    let title: String
    let isAnonymous: Bool
    let allowMultipleChoice: Bool
    let startsAt: String
    let endsAtExclusive: String
    let options: [NoticeDetailVoteOptionDTO]
    let mySelectedOptionIds: [String]

    private enum CodingKeys: String, CodingKey {
        case voteId
        case title
        case isAnonymous
        case allowMultipleChoice
        case startsAt
        case endsAtExclusive
        case options
        case mySelectedOptionIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.voteId = try container.decodeStringFlexible(forKey: .voteId)
        self.title = try container.decode(String.self, forKey: .title)
        self.isAnonymous = try container.decode(Bool.self, forKey: .isAnonymous)
        self.allowMultipleChoice = try container.decode(Bool.self, forKey: .allowMultipleChoice)
        self.startsAt = try container.decode(String.self, forKey: .startsAt)
        self.endsAtExclusive = try container.decode(String.self, forKey: .endsAtExclusive)
        self.options = try container.decode([NoticeDetailVoteOptionDTO].self, forKey: .options)
        self.mySelectedOptionIds = try container.decodeStringArrayFlexible(forKey: .mySelectedOptionIds)
    }

    func toDomain() -> NoticeVote {
        NoticeVote(
            id: voteId,
            question: title,
            options: options.map { $0.toDomain() },
            startDate: parseISO8601(startsAt),
            endDate: parseISO8601(endsAtExclusive),
            allowMultipleChoices: allowMultipleChoice,
            isAnonymous: isAnonymous,
            userVotedOptionIds: mySelectedOptionIds
        )
    }
}

struct NoticeDetailVoteOptionDTO: Codable {
    let optionId: String
    let content: String
    let voteCount: String

    private enum CodingKeys: String, CodingKey {
        case optionId
        case content
        case voteCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.optionId = try container.decodeStringFlexible(forKey: .optionId)
        self.content = try container.decode(String.self, forKey: .content)
        self.voteCount = try container.decodeStringFlexible(forKey: .voteCount)
    }

    func toDomain() -> VoteOption {
        VoteOption(id: optionId, title: content, voteCount: Int(voteCount) ?? 0)
    }
}

struct NoticeDetailImageDTO: Codable {
    let id: String
    let url: String
    let displayOrder: String

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeStringFlexible(forKey: .id)
        self.url = try container.decode(String.self, forKey: .url)
        self.displayOrder = try container.decodeStringFlexible(forKey: .displayOrder)
    }
}

struct NoticeDetailLinkDTO: Codable {
    let id: String
    let url: String
    let displayOrder: String

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case displayOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeStringFlexible(forKey: .id)
        self.url = try container.decode(String.self, forKey: .url)
        self.displayOrder = try container.decodeStringFlexible(forKey: .displayOrder)
    }
}

private extension KeyedDecodingContainer {
    func decodeStringFlexible(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(Int(value))
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected String/Int/Double for key '\(key.stringValue)'"
            )
        )
    }

    func decodeStringArrayFlexible(forKey key: Key) throws -> [String] {
        if let values = try? decode([String].self, forKey: key) {
            return values
        }
        if let values = try? decode([Int].self, forKey: key) {
            return values.map(String.init)
        }
        return []
    }
}

private func parseISO8601(_ value: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = formatter.date(from: value) {
        return parsed
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: value) ?? Date()
}
