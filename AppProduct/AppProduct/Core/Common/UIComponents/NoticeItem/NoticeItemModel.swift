//
//  NoticeItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

struct NoticeItemModel: Equatable, Identifiable {
    let id = UUID()
    let generation: Int
    // 공지 출처 (중앙/지부/교내)
    let scope: NoticeScope
    // 공지 카테고리 (일반/파트별)
    let category: NoticeCategory
    let mustRead: Bool
    let isAlert: Bool
    let date: Date
    let title: String
    let content: String
    let writer: String
    let hasLink: Bool
    let hasVote: Bool
    let viewCount: Int

    /// UI 표시용 태그 (scope + category 조합)
    var tag: NoticeItemTag {
        NoticeItemTag(scope: scope, category: category)
    }
}
