//
//  RecentNoticeData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

/// 최근 공지 카드 모델
struct RecentNoticeData: Equatable, Identifiable {
    let id: UUID = .init()
    let category: RecentCategory
    let title: String
    let createdAt: Date
}
