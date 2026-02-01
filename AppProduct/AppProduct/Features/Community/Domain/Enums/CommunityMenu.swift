//
//  CommunityMenu.swift
//  AppProduct
//
//  Created by 김미주 on 1/29/26.
//

import Foundation

enum CommunityMenu: String, Identifiable, CaseIterable {
    case all = "전체"
    case question = "질문"
    case party = "번개모임"
    case fame = "명예의전당"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return ""
        case .question: return "flame.fill"
        case .party: return "bolt.fill"
        case .fame: return "trophy.fill"
        }
    }
}
