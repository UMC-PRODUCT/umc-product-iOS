//
//  MySuggestionItemStatus.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - 답변 상태

enum MySuggestionItemStatus {
    case answered
    case pending

    var text: String {
        switch self {
        case .answered: return "답변완료"
        case .pending: return "답변대기"
        }
    }

    var mainColor: Color {
        switch self {
        case .answered: return .green500
        case .pending: return .black
        }
    }

    var subColor: Color {
        switch self {
        case .answered: return .green100
        case .pending: return .gray
        }
    }
}
