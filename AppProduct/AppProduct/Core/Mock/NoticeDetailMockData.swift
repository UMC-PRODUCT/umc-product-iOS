//
//  NoticeDetailMockData.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import Foundation

enum NoticeDetailMockData {
    static let sampleNotice = NoticeDetail(
        id: "1",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: true,
        title: "[투표] 12기 중앙 해커톤 회차 선정 안내",
        content: """
        안녕하세요, 12기 운영진입니다.

        이번 해커톤 종료 후 진행될 회차를 결정하고자 합니다. 가장 많은 표를 받은 메뉴로 모두 진행하게 될 예정이니 신중하게 투표해주시기 바랍니다!

        투표 기간: ~3/20(수) 18:00
        """,
        authorID: "author123",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -86400 * 3),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false
    )

    static let sampleNoticeWithPermission = NoticeDetail(
        id: "2",
        generation: 9,
        scope: .branch,
        category: .part(.ios),
        isMustRead: true,
        title: "iOS 파트 스터디 일정 안내",
        content: """
        iOS 파트 스터디 일정을 안내드립니다.

        일시: 매주 수요일 19:00
        장소: 강남역 스터디룸
        """,
        authorID: "current_user",
        authorName: "소피/이예지-UMC 9th iOS 파트장",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -3600),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 9,
            scope: .campus,
            parts: [.ios],
            branches: [],
            schools: []
        ),
        hasPermission: true
    )

    static let items: [NoticeDetail] = [
        sampleNotice,
        sampleNoticeWithPermission
    ]
}
