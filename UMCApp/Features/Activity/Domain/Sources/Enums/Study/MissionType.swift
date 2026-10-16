//
//  MissionType.swift
//  ActivityDomain
//
//  Created by jaewon Lee on 5/11/26.
//

import Foundation

/// 커리큘럼 미션 타입
///
/// 서버 `missionType` 문자열과 매핑됩니다.
public enum MissionType: String, Codable, Equatable {
    case link = "LINK"
    case memo = "MEMO"
    case plain = "PLAIN"
    case unknown

    public init(rawValue: String) {
        switch rawValue.uppercased() {
        case "LINK":
            self = .link
        case "MEMO":
            self = .memo
        case "PLAIN":
            self = .plain
        default:
            self = .unknown
        }
    }
}
