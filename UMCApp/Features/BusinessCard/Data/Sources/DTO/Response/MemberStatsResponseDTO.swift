//
//  MemberStatsResponseDTO.swift
//  BusinessCardData
//
//  Created by euijjang97 on 8/30/26.
//

import Foundation
import UMCFoundation

/// 마이페이지 통합 카운트 (`GET /api/v2/member/me/stats`).
///
/// 두 값 모두 non-null 이다 — 「0건」과 「못 셌다」를 서버가 섞지 않는다. 셀 수 없는
/// 상태(활성 챌린저 없는 휴지기 등)도 `"0"` 으로 내려온다.
///
/// `activityCount` 는 요청하지 않는다. 「나의 활동·프로젝트」 수는 마이페이지 목록과 같은
/// ``CoreDomain/Profile/activityLogs()`` 배열에서 나와야 하고(#1222), 원천 데이터는 이미
/// 프로필 응답으로 앱에 캐시돼 있어 왕복이 0회다.
public struct MemberStatsResponseDTO: Codable, Equatable, Sendable {

    // MARK: - Property

    public let receivedCardCount: String
    public let studyCount: String

    // MARK: - Init

    public init(receivedCardCount: String, studyCount: String) {
        self.receivedCardCount = receivedCardCount
        self.studyCount = studyCount
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case receivedCardCount, studyCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        receivedCardCount = try container.decodeFlexibleString(forKey: .receivedCardCount)
        studyCount = try container.decodeFlexibleString(forKey: .studyCount)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(receivedCardCount, forKey: .receivedCardCount)
        try container.encode(studyCount, forKey: .studyCount)
    }
}
