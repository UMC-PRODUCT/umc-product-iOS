//
//  ProfileChallengerRecord+HomeMapping.swift
//  HomeData
//
//  Created by euijjang97 on 7/11/26.
//

import CoreDomain
import Foundation
import HomeDomain
import UMCFoundation

// MARK: - ProfileChallengerRecord → HomeGeneration

extension ProfileChallengerRecord {
    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        formatter.timeZone = ServerDateTimeConverter.kstTimeZone
        formatter.locale = Locale(identifier: "ko_KR_POSIX")
        return formatter
    }()

    /// 기수별 상벌점 현황(``HomeGeneration``)으로 변환한다.
    func toHomeGeneration() -> HomeGeneration {
        let sortedPoints = challengerPoints.sorted { lhs, rhs in
            let lhsDate = ServerDateTimeConverter.parseUTCDateTime(lhs.createdAt) ?? .distantPast
            let rhsDate = ServerDateTimeConverter.parseUTCDateTime(rhs.createdAt) ?? .distantPast
            return lhsDate > rhsDate
        }

        var rewardTotal: Double = 0
        var penaltyTotal: Double = 0

        let pointLogs = sortedPoints.map { point -> PointLog in
            let isReward = point.point > 0

            if isReward {
                rewardTotal += abs(point.point)
            } else {
                penaltyTotal += abs(point.point)
            }

            return PointLog(
                id: point.id,
                reason: point.description,
                date: Self.displayDateString(from: point.createdAt),
                point: point.point,
                isReward: isReward
            )
        }

        return HomeGeneration(
            gisuId: gisuId,
            gen: gisu,
            penaltyPoint: penaltyTotal,
            rewardPoint: rewardTotal,
            pointLogs: pointLogs
        )
    }

    private static func displayDateString(from rawValue: String) -> String {
        guard let date = ServerDateTimeConverter.parseUTCDateTime(rawValue) else { return "" }
        return displayDateFormatter.string(from: date)
    }
}

// MARK: - Profile → Home 시즌 카드 소스

extension Profile {
    /// 챌린저 기록(challengerRecords)에서 기수별 상벌점 현황을 구성한다.
    func toHomeGenerations() -> [HomeGeneration] {
        challengerRecords.map { $0.toHomeGeneration() }
    }

    /// 활동일 계산을 위해 기수 시작일을 조회해야 하는 대상 기수 ID 목록.
    ///
    /// 역할(roles)과 챌린저 기록(challengerRecords) 양쪽에서 기수 ID(`gisuId`)를 모아
    /// 합집합을 구성한다.
    func targetGisuIds() -> [String] {
        let recordGisuIds = challengerRecords.map(\.gisuId)
        let roleGisuIds = roles.map(\.gisuId)
        return Array(Set(recordGisuIds + roleGisuIds).filter { !$0.isEmpty && $0 != "0" })
    }
}
