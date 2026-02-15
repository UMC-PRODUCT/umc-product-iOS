//
//  OAuthProvider.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

/// OAuth provider 타입
///
/// 스웨거 enum 기준(APPLE, KAKAO)으로 모델링합니다.
/// 지원하지 않는 값은 .unknown으로 디코딩하여 화면에서 무시합니다.
enum OAuthProvider: Equatable, Sendable {
    /// Apple 로그인
    case apple
    /// Kakao 로그인
    case kakao
    /// 서버에서 내려온 알 수 없는 provider (하위 호환용)
    case unknown(String)
}

// MARK: - Codable

extension OAuthProvider: Codable {
    /// 서버 raw 문자열("APPLE", "KAKAO")을 enum case로 변환
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

// MARK: - Conversion

extension OAuthProvider {
    /// 앱 내부에서 사용하는 `SocialType`으로 변환
    ///
    /// - Returns: 매핑되는 SocialType, unknown인 경우 nil
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
