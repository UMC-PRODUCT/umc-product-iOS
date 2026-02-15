//
//  NoticeTargetInfoMapper.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

extension NoticeTargetInfoDTO {
    var generationValue: Int {
        Int(targetGisuId) ?? 0
    }

    var resolvedScope: NoticeScope {
        if targetSchoolId != nil {
            return .campus
        }
        if targetChapterId != nil {
            return .branch
        }
        return .central
    }

    var resolvedCategory: NoticeCategory {
        if let part = targetParts?.first {
            return .part(part.toPart())
        }
        return .general
    }

    var resolvedParts: [Part] {
        (targetParts ?? []).map { $0.toPart() }
    }

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
