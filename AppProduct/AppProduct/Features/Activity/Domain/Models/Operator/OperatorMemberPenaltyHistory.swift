//
//  OperatorMemberPenaltyHistory.swift
//  AppProduct
//
//  Created by 이예지 on 2/16/26.
//

import Foundation

/// 운영진 멤버 관리 히스토리
///
/// 멤버 상벌점 히스토리를 나타내는 모델입니다.
struct OperatorMemberPenaltyHistory: Identifiable, Equatable {
    let id: UUID

    /// 서버 포인트 식별자
    let challengerPointId: Int?

    /// 날짜
    let date: Date

    /// 사유
    let reason: String

    /// 포인트 점수 (절대값)
    let penaltyScore: Double

    /// 포인트 유형
    let pointType: ChallengerPointType

    init(
        id: UUID = UUID(),
        challengerPointId: Int? = nil,
        date: Date,
        reason: String,
        penaltyScore: Double,
        pointType: ChallengerPointType = .out
    ) {
        self.id = id
        self.challengerPointId = challengerPointId
        self.date = date
        self.reason = reason
        self.penaltyScore = penaltyScore
        self.pointType = pointType
    }
}
