//
//  NoticeItemTag.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

enum NoticeItemTag {
    case all
    case central
    case chapter
    case campus
    case part

    var text: String {
        switch self {
        case .all: return "전체"
        case .central: return "중앙"
        case .chapter: return "지부"
        case .campus: return "학교"
        case .part: return "파트"
        }
    }

    var textColor: Color {
        switch self {
        case .central: return .white
        case .all, .chapter, .campus, .part: return .green
        }
    }

    var backColor: Color {
        switch self {
        case .central: return .blue
        case .all, .chapter, .campus, .part: return .green.opacity(0.1)
        }
    }

    var borderColor: Color {
        switch self {
        case .central: return .clear
        case .all, .chapter, .campus, .part: return .green.opacity(0.3)
        }
    }
}
