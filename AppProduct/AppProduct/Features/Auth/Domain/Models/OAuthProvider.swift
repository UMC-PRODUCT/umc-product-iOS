//
//  OAuthProvider.swift
//  AppProduct
//
//  Created by Codex on 2/15/26.
//

import Foundation

/// OAuth provider 타입
///
/// 스웨거 enum 기준(APPLE, KAKAO)으로 모델링합니다.
/// 지원하지 않는 값은 .unknown으로 디코딩하여 화면에서 무시합니다.
enum OAuthProvider: Equatable, Sendable {
    case apple
    case kakao
    case unknown(String)
}

extension OAuthProvider: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        switch raw.uppercased() {
        case "APPLE":
            self = .apple
        case "KAKAO":
            self = .kakao
        default:
            self = .unknown(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .apple:
            try container.encode("APPLE")
        case .kakao:
            try container.encode("KAKAO")
        case .unknown(let raw):
            try container.encode(raw)
        }
    }
}

extension OAuthProvider {
    var socialType: SocialType? {
        switch self {
        case .apple:
            return .apple
        case .kakao:
            return .kakao
        case .unknown:
            return nil
        }
    }
}
