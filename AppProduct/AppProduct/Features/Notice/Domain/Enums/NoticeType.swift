//
//  NoticeType.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import Foundation
import SwiftUI


// MARK: - NoticeType
/// NoticeChip에 쓰이는 enum
enum NoticeType: String, Equatable {
    case essential = "필독"
    case core = "중앙"
    case branch = "지부"
    case campus = "교내"
    case part = "파트"
    
    var textColor: Color {
        switch self {
        case .essential:
            return .indigo500
        default:
            return .white
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .essential:
            return .indigo100
        default:
            return .indigo500
        }
    }
}
