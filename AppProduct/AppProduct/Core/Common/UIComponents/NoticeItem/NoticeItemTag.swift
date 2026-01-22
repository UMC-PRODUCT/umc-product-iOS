//
//  NoticeItemTag.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

enum NoticeItemTag: Equatable {
    case all
    case central
    case chapter
    case campus
    case part(Part)

    var text: String {
        switch self {
        case .all: return "전체"
        case .central: return "중앙"
        case .chapter: return "지부"
        case .campus: return "학교"
        case .part(let part): return part.name
        }
    }

    var backColor: Color {
        switch self {
        case .central: return .blue
        case .all, .chapter, .campus, .part: return .green
        }
    }
}
