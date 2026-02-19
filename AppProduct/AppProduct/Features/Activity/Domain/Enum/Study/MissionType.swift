//
//  MissionType.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import Foundation

/// 워크북 미션 제출 타입
///
/// 서버 `missionType` 문자열과 매핑됩니다.
enum MissionType: String, Codable, Equatable {
    case link = "LINK"
    case memo = "MEMO"
    case plain = "PLAIN"
    case unknown

    init(rawValue: String) {
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

    /// UI에서 허용할 제출 방식 목록
    var availableSubmissionTypes: [MissionSubmissionType] {
        switch self {
        case .link:
            return [.link]
        case .memo, .plain:
            return [.completeOnly]
        case .unknown:
            return MissionSubmissionType.allCases
        }
    }

    var defaultSubmissionType: MissionSubmissionType {
        availableSubmissionTypes.first ?? .link
    }
}
