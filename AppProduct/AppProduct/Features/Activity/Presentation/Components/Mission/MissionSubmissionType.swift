//
//  MissionSubmissionType.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionSubmissionType

/// 미션 제출 타입
enum MissionSubmissionType: String, CaseIterable {
    case link = "링크"
    case completeOnly = "완료만"

    var icon: String {
        switch self {
        case .link: return "link"
        case .completeOnly: return "checkmark.square"
        }
    }
}
