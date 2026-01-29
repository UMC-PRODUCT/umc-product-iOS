//
//  CommunityItemCategory.swift
//  AppProduct
//
//  Created by 김미주 on 1/14/26.
//

import Foundation

enum CommunityItemCategory: Hashable, CaseIterable {
    case question
    case hobby
    case impromptu
    // TODO: 태그 추가 - [김미주] 26.01.08

    var text: String {
        switch self {
        case .question:
            return "🔥 질문"
        case .hobby:
            return "⚽️ 취미"
        case .impromptu:
            return "⚡️ 번개"
        }
    }
}
