//
//  RecentNoticeData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

/// 최근 공지 카드 모델
/// 최근 공지사항 데이터 모델
///
/// 홈 화면에서 보여줄 최신 공지사항의 정보를 담고 있습니다.
struct RecentNoticeData: Equatable, Identifiable {
    
    /// 고유 식별자
    let id: UUID = .init()

    /// 공지 ID (상세 조회용)
    let noticeId: Int
    
    /// 공지 카테고리 (학교, 운영진, 지부 등)
    let category: RecentCategory
    
    /// 공지사항 제목
    let title: String
    
    /// 공지사항 작성 일시
    let createdAt: Date

    init(
        noticeId: Int = 0,
        category: RecentCategory,
        title: String,
        createdAt: Date
    ) {
        self.noticeId = noticeId
        self.category = category
        self.title = title
        self.createdAt = createdAt
    }
}
