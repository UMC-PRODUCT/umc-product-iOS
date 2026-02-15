//
//  NoticeItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

/// 공지사항 목록 아이템 모델
///
/// 공지 리스트 셀에 표시할 정보를 담으며, scope/category 조합으로 태그를 생성합니다.
struct NoticeItemModel: Equatable, Identifiable {
    let id = UUID()
    let noticeId: String
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
    let links: [String]
    let images: [String]
    let vote: NoticeVote?
    let viewCount: Int

    init(
        noticeId: String = UUID().uuidString,
        generation: Int,
        scope: NoticeScope,
        category: NoticeCategory,
        mustRead: Bool,
        isAlert: Bool,
        date: Date,
        title: String,
        content: String,
        writer: String,
        links: [String],
        images: [String],
        vote: NoticeVote?,
        viewCount: Int
    ) {
        self.noticeId = noticeId
        self.generation = generation
        self.scope = scope
        self.category = category
        self.mustRead = mustRead
        self.isAlert = isAlert
        self.date = date
        self.title = title
        self.content = content
        self.writer = writer
        self.links = links
        self.images = images
        self.vote = vote
        self.viewCount = viewCount
    }
    
    /// UI 표시용 태그 (scope + category 조합)
    var tag: NoticeItemTag {
        NoticeItemTag(scope: scope, category: category)
    }
    
    var hasLink: Bool { !links.isEmpty }
    var hasVote: Bool { vote != nil }
}

extension NoticeItemModel {
    /// 목록 아이템을 상세 화면용 NoticeDetail로 변환합니다.
    func toNoticeDetail() -> NoticeDetail {
        NoticeDetail(
            id: noticeId,
            generation: generation,
            scope: scope,
            category: category,
            isMustRead: mustRead,
            title: title,
            content: content,
            authorID: "temp-\(id)",
            authorName: writer,
            authorImageURL: nil,
            createdAt: date,
            updatedAt: nil,
            targetAudience: .all(generation: generation, scope: scope),
            hasPermission: false,
            images: images,
            links: links,
            vote: vote
        )
    }
}
