//
//  NoticeItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

struct NoticeItemModel: Equatable, Identifiable {
    let id = UUID()
    let tag: NoticeItemTag
    let mustRead: Bool
    let isAlert: Bool
    let date: Date
    let title: String
    let content: String
    let writer: String
    let hasLink: Bool
    let hasVote: Bool
    let viewCount: Int
}
