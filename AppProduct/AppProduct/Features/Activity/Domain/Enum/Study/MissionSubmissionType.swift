//
//  MissionSubmissionType.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionSubmissionType

/// 미션 제출 방식
///
/// 링크 제출 또는 완료 확인만 선택할 수 있습니다.
enum MissionSubmissionType: String, CaseIterable {
    case link = "링크"
    case completeOnly = "완료만"

    /// 제출 타입에 해당하는 SF Symbol 아이콘명
    var icon: String {
        switch self {
        case .link: return "link"
        case .completeOnly: return "checkmark.circle"
        }
    }
}
