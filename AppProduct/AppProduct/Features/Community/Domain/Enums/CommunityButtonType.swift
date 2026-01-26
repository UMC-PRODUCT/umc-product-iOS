//
//  CommunityButtonType.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

enum CommunityButtonType {
    case like
    case comment

    var icon: String {
        switch self {
        case .like:
            return "heart"
        case .comment:
            return "bubble"
        }
    }

    var filledIcon: String {
        switch self {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .like:
            return .red.opacity(0.1)
        case .comment:
            return .blue.opacity(0.1)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .like:
            return .red
        case .comment:
            return .indigo600
        }
    }
}
