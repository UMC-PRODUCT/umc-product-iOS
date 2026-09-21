//
//  OperatorMemberPenaltyHistory.swift
//  ActivityDomain
//
//  Created by jaewon Lee on 6/17/26.
//

import Foundation
import UMCFoundation

/// 운영진 멤버 관리 히스토리
///
/// 멤버 상벌점 히스토리를 나타내는 모델입니다.
public struct OperatorMemberPenaltyHistory: Identifiable, Equatable {

    // MARK: - Property

    /// 고유 식별자 (클라이언트 생성)
    public let id: UUID

    /// 서버 포인트 식별자 (서버 응답)
    public let challengerPointId: String?

    /// 날짜
    public let date: Date

    /// 사유
    public let reason: String

    public let signedPoint: Double
    public var penaltyScore: Double { abs(signedPoint) }
    public var isReward: Bool { Self.isReward(type: pointType, signedPoint: signedPoint) }

    public static func isReward(type: ChallengerPointType, signedPoint: Double) -> Bool {
        type.isCustom ? signedPoint > 0 : type.isReward
    }

    /// 포인트 유형
    public let pointType: ChallengerPointType

    // MARK: - Initializer

    public init(
        id: UUID = UUID(),
        challengerPointId: String? = nil,
        date: Date,
        reason: String,
        penaltyScore: Double,
        pointType: ChallengerPointType,
        signedPoint: Double? = nil
    ) {
        self.id = id
        self.challengerPointId = challengerPointId
        self.date = date
        self.reason = reason
        self.signedPoint = signedPoint ?? penaltyScore
        self.pointType = pointType
    }
}
