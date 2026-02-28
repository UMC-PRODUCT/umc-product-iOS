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
    case information = "INFORMATION"
    case habit = "HABIT"

    var text: String {
        switch self {
        case .lighting:
            return "⚡️ 번개"
        case .question:
            return "🔥 질문"
        case .free:
            return "💌 자유"
        case .information:
            return "📚 정보"
        case .habit:
            return "📝 습관"
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
        case .information:
            return .orange100
        case .habit:
            return .green100
        }
    }

    /// 서버 API 문자열로부터 생성
    init?(apiValue: String) {
        switch apiValue {
        case "LIGHTNING":        self = .lighting
        case "QUESTION":      self = .question
        case "FREE":  self = .free
        case "INFORMATION":  self = .information
        case "HABIT":        self = .habit
        default:            return nil
        }
    }
}
