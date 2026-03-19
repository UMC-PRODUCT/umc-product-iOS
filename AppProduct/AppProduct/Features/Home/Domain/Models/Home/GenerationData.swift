//
//  File.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import Foundation

/// 기수별 데이터
/// 기수별 활동 데이터 모델
///
/// 특정 기수의 패널티 점수 및 패널티 기록 목록을 포함합니다.
struct GenerationData: Identifiable, Equatable {

    /// 고유 식별자
    let id = UUID()

    /// 서버 기수 식별 ID
    let gisuId: Int

    /// 기수 번호 (예: 9, 10, 11)
    let gen: Int

    /// 현재 벌점 총점
    let penaltyPoint: Int

    /// 현재 상점 총점
    let rewardPoint: Int

    /// 상벌점 통합 기록 (최근 3건)
    let pointLogs: [PointLogItem]

    /// 패널티 상세 기록 리스트 (하위호환)
    let penaltyLogs: [PenaltyInfoItem]
}
