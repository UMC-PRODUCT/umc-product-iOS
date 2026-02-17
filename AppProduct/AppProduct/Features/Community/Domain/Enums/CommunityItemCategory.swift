//
//  CommunityItemCategory.swift
//  AppProduct
//
//  Created by 김미주 on 1/14/26.
//

import SwiftUI

enum CommunityItemCategory: String, Hashable, CaseIterable, Codable {
    case lighting = "LIGHTNING"
    case question = "QUESTION"
    case free = "FREE"

    var text: String {
        switch self {
        case .lighting:
            return "⚡️ 번개"
        case .question:
            return "🔥 질문"
        case .free:
            return "💌 자유"
        }
    }
    
    var color: Color {
        switch self {
        case .lighting:
            return .yellow100
        case .question:
            return .red100
        case .free:
            return .indigo200
        }
    }
}
