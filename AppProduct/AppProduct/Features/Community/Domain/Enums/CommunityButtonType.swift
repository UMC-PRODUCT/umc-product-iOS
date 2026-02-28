//
//  CommunityButtonType.swift
//  AppProduct
//
//  Created by 김미주 on 1/26/26.
//

import SwiftUI

enum CommunityButtonType {
    case like
    case scrap

    var icon: String {
        switch self {
        case .like:
            return "heart"
        case .scrap:
            return "bookmark"
        }
    }

    var filledIcon: String {
        switch self {
        case .like:
            return "heart.fill"
        case .scrap:
            return "bookmark.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .like:
            return .red.opacity(0.1)
        case .scrap:
            return .yellow500.opacity(0.1)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .like:
            return .red
        case .scrap:
            return .yellow500
        }
    }
}
