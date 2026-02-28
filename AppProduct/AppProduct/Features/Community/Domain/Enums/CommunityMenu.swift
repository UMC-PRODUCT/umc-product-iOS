//
//  CommunityMenu.swift
//  AppProduct
//
//  Created by 김미주 on 1/29/26.
//

import Foundation

enum CommunityMenu: String, Identifiable, CaseIterable {
    case all = "전체"
    case party = "번개 모임"
    case question = "질문"
    case information = "정보"
    case habit = "습관"
    case free = "자유"
    case fame = "명예의 전당"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .party: return "bolt.fill"
        case .question: return "flame.fill"
        case .information: return "text.book.closed.fill"
        case .habit: return "pencil.and.ruler.fill"
        case .free: return "envelope.open.fill"
        case .fame: return "trophy.fill"
        }
    }
    
    func toCategoryType() -> String? {
        switch self {
        case .all, .fame: return nil
        case .party: return "LIGHTNING"
        case .question: return "QUESTION"
        case .information: return "INFORMATION"
        case .habit: return "HABIT"
        case .free: return "FREE"
        }
    }
}
