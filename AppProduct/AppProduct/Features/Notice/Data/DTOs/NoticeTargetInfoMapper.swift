//
//  NoticeTargetInfoMapper.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

/// NoticeTargetInfoDTO → 도메인 모델 변환 유틸리티
extension NoticeTargetInfoDTO {

    // MARK: - Computed Property
    /// 기수 ID를 Int로 변환 (실패 시 0)
    var generationValue: Int {
        Int(targetGisuId) ?? 0
    }

    /// targetInfo 기반으로 공지 출처(scope)를 추론합니다.
    var resolvedScope: NoticeScope {
        if targetSchoolId != nil {
            return .campus
        }
        if targetChapterId != nil {
            return .branch
        }
        return .central
    }

    /// targetInfo 기반으로 공지 카테고리를 추론합니다.
    var resolvedCategory: NoticeCategory {
        if let part = targetParts?.first {
            return .part(part)
        }
        return .general
    }

    var resolvedParts: [UMCPartType] {
        targetParts ?? []
    }

    // MARK: - Function
    /// TargetAudience 도메인 모델로 변환합니다.
    func toTargetAudience(scope: NoticeScope? = nil) -> TargetAudience {
        TargetAudience(
            generation: generationValue,
            scope: scope ?? resolvedScope,
            parts: resolvedParts,
            branches: [],
            schools: []
        )
    }
}
