//
//  PenaltyRecord.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
import SwiftData

/// 기수별 패널티 데이터 로컬 저장 모델 (SwiftData + CloudKit Sync)
///
/// API에서 받은 현재 기수 패널티를 기수별로 누적 저장하여,
/// 과거 기수 데이터도 조회할 수 있도록 합니다.
@Model
class PenaltyRecord {

    // MARK: - Property

    /// 서버 기수 식별 ID
    var gisuId: Int

    /// 기수 번호 (예: 9, 10, 11)
    var gen: Int

    /// 패널티 총점
    var penaltyPoint: Int

    /// [PenaltyInfoItem] JSON 인코딩 데이터
    var logsData: Data

    /// 마지막 업데이트 시간
    var updatedAt: Date

    // MARK: - Init

    init(
        gisuId: Int,
        gen: Int,
        penaltyPoint: Int,
        logsData: Data,
        updatedAt: Date = .now
    ) {
        self.gisuId = gisuId
        self.gen = gen
        self.penaltyPoint = penaltyPoint
        self.logsData = logsData
        self.updatedAt = updatedAt
    }
}
