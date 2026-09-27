//
//  NoticeSelectablePartDTO.swift
//  NoticeData
//
//  Created by euijjang97 on 9/27/26.
//

import Foundation

public struct NoticeSelectablePartDTO: Codable {
    public let name: String
    public let displayName: String

    private enum CodingKeys: String, CodingKey {
        case name, displayName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
    }
}
