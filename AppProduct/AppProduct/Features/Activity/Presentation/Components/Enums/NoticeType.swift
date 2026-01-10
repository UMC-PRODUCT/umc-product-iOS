//
//  NoticeType.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import Foundation
import SwiftUI

enum NoticeType {
    case essential
    case target
    
    var textColor: Color {
        switch self {
        case .essential:
            return .primary600
        case .target:
            return .white
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .essential:
            return .primary100
        case .target:
            return .primary600
        }
    }
}
