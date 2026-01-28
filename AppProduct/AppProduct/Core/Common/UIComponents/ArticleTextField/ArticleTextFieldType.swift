//
//  ArticleTextFieldType.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import Foundation
import SwiftUI

enum ArticleTextFieldType {
    case title
    case content
    
    var placeholderLabel: String {
        switch self {
        case .title:
            return "제목을 입력하세요."
        case .content:
            return "내용을 입력하세요."
        }
    }
    
    var placeholderFont: AppFont {
        switch self {
        case .title:
            return .title3Emphasis
        case .content:
            return .body
        }
    }
    
    var axis: Axis {
        switch self {
        case .title:
            return .horizontal
        case .content:
            return .vertical
        }
    }
    
    var scrollIndicator: ScrollIndicatorVisibility {
        switch self {
        case .title:
            return .hidden
        case .content:
            return .visible
        }
    }
}
