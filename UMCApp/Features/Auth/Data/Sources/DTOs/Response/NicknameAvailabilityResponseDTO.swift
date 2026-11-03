//
//  NicknameAvailabilityResponseDTO.swift
//  AuthData
//
//  Created by euijjang97 on 11/3/26.
//

struct NicknameAvailabilityResponseDTO: Codable {
    let available: Bool

    private enum CodingKeys: CodingKey {
        case available
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        available = try container.decode(Bool.self, forKey: .available)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(available, forKey: .available)
    }
}
