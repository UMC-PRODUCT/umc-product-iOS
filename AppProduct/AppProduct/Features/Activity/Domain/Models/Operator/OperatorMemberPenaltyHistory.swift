//
//  OperatorMemberPenaltyHistory.swift
//  AppProduct
//
//  Created by 이예지 on 2/16/26.
//

import Foundation

/// 운영진 멤버 관리 히스토리
///
/// 멤버 아웃 히스토리를 나타내는 모델입니다.
struct OperatorMemberPenaltyHistory: Identifiable, Equatable {
    let id: UUID = UUID()
    
    /// 날짜
    let date: Date
    
    /// 사유
    let reason: String
    
    /// 페널티 점수
    let penaltyScore: Double
}
