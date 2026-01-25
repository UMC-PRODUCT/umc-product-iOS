//
//  ScheduleGenerationType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import SwiftUI

/// 일정 등록 뷰 Section Type
enum ScheduleGenerationType: CaseIterable {
    case title
    case place
    case allDay
    case date
    case memo
    case participation
    case tag
    
    /// 안내 가이드
    var placeholder: String? {
        switch self {
        case .title:
            return "어떤 일정인가요?"
        case .place:
            return "어디에서 열리나요?"
        case .allDay:
            return "하루 종일"
        case .date:
            return "언제 열리나요?"
        case .memo:
            return "메모를 남겨보세요"
        case .participation:
            return "누가 함께하나요?"
        case .tag:
            return nil
        }
    }
    
    var placeholderFont: Font {
        return .app(.callout)
    }
    
    var placeholderColor: Color {
        return .gray
    }
    
}
