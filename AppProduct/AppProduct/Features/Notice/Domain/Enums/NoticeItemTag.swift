//
//  NoticeItemTag.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

/// UI 표시용 공지 태그
struct NoticeItemTag: Equatable {

    // MARK: - Property

    let scope: NoticeScope
    let category: NoticeCategory

    // MARK: - Computed Property

    /// 태그 텍스트
    var text: String {
        switch category {
        case .general:
            switch scope {
            case .central: return "중앙"
            case .branch: return "지부"
            case .campus: return "학교"
            }
        case .part(let part):
            return NoticePart(umcPartType: part)?.displayName ?? "파트"
        }
    }

    /// 태그 배경색
    var backColor: Color {
        switch category {
        case .general:
            switch scope {
            case .central: return .blue
            case .branch: return .orange500
            case .campus: return .green500
            }
        case .part(let part):
            // Activity 탭과 동일한 파트 색상 규칙을 사용합니다.
            return part.color
        }
    }
}
