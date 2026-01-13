//
//  CommunityItemStatus.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - 모집 상태

enum CommunityItemStatus {
    case upcoming
    case recruiting
    case closed

    var text: String {
        switch self {
        case .upcoming: return "예정"
        case .recruiting: return "모집중"
        case .closed: return "마감"
        }
    }
}
