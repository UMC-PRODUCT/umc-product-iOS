//
//  NoticeItemTag.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

/// UI 표시용 공지 태그
struct NoticeItemTag: Equatable {
    let scope: NoticeScope
    let category: NoticeCategory

    /// 태그 텍스트
    var text: String {
        switch category {
        case .general:
            switch scope {
            case .central: return "중앙"
            case .branch: return "지부"
            case .campus: return "학교"
            }
        case .part:
            return "파트"
        }
    }

    /// 태그 배경색
    var backColor: Color {
        switch scope {
        case .central: return .blue
        case .branch: return .orange
        case .campus: return .green
        }
    }
}
