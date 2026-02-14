//
//  PenaltyRecord.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation
import SwiftData

/// 기수-기수ID 매핑 로컬 저장 모델 (SwiftData + CloudKit Sync)
///
/// 홈 프로필 응답에서 파생한 (gen, gisuId) 매핑을 저장합니다.
@Model
class GenerationMappingRecord {

    // MARK: - Property

    /// 서버 기수 식별 ID
    var gisuId: Int

    /// 기수 번호 (예: 9, 10, 11)
    var gen: Int

    /// 마지막 업데이트 시간
    var updatedAt: Date

    // MARK: - Init

    init(
        gisuId: Int,
        gen: Int,
        updatedAt: Date = .now
    ) {
        self.gisuId = gisuId
        self.gen = gen
        self.updatedAt = updatedAt
    }
}
