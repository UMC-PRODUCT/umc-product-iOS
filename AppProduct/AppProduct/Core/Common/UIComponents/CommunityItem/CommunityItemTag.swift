//
//  CommunityItemTag.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

enum CommunityItemTag {
    case feedback
    case cheerUp
    // TODO: 태그 추가 - [김미주] 26.01.14

    var text: String {
        switch self {
        case .feedback:
            return "🔥 피드백환영"
        case .cheerUp:
            return "🐥 응원해줘요"
        }
    }
}
