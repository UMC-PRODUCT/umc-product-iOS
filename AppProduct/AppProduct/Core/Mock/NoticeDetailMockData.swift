//
//  NoticeDetailMockData.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import Foundation

// MARK: - NoticeDetail Mock
/// 공지 상세 화면 미리보기/디버그 상태에서 사용하는 샘플 데이터 모음입니다.
enum NoticeDetailMockData {

    // MARK: - Samples

    /// 기본 공지 샘플 (투표 포함, 권한 없음)
    static let sampleNotice = NoticeDetail(
        id: "1",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: true,
        title: "[투표] 12기 중앙 해커톤 회식 메뉴 선정 안내",
        content: """
        안녕하세요, 12기 운영진입니다.
                                                                                                                                             
        이번 해커톤 종료 후 진행될 회식 메뉴를 결정하고자 합니다. 가장 많은 표를 받은 메뉴로 모두 진행하게 될 예정이니 신중하게 투표해주시기
        바랍니다!
                                                                                                                                             
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
        hasPermission: false,
        images: [],
        links: [],
        vote: NoticeVote(
            id: "vote1",
            question: "다음 해커톤 주제로 어떤 것이 좋을까요?",
            options: [
                VoteOption(id: "1", title: "삼겹살", voteCount: 45),
                VoteOption(id: "2", title: "치킨", voteCount: 23),
                VoteOption(id: "3", title: "피자", voteCount: 18),
                VoteOption(id: "4", title: "떡볶이", voteCount: 34)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 7),
            allowMultipleChoices: false,
            isAnonymous: true,
            userVotedOptionIds: []
        )
    )
    
    /// 수정/삭제 권한이 있는 공지 샘플
    static let sampleNoticeWithPermission = NoticeDetail(
        id: "2",
        generation: 9,
        scope: .branch,
        category: .part(.front(type: .ios)),
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
            parts: [.front(type: .ios)],
            branches: [],
            schools: []
        ),
        hasPermission: true,
        images: [],
        links: [],
        vote: nil
    )
    
    /// 이미지 첨부 공지 샘플
    static let sampleNoticeWithImages = NoticeDetail(
        id: "3",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: false,
        title: "12기 해커톤 현장 사진 공유",
        content: """
        안녕하세요! 지난 주말 진행된 해커톤 현장 사진을 공유합니다.
                                                                                                                                             
        모두 고생하셨습니다!
        """,
        authorID: "author123",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -86400),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [
            "https://picsum.photos/400/400",
            "https://picsum.photos/400/401",
            "https://picsum.photos/400/402",
            "https://picsum.photos/400/403",
            "https://picsum.photos/400/404"
        ],
        links: [],
        vote: nil
    )
    
    /// 링크 첨부 공지 샘플
    static let sampleNoticeWithLinks = NoticeDetail(
        id: "4",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: true,
        title: "UMC 12기 커리큘럼 및 참고자료 안내",
        content: """
        안녕하세요, 12기 운영진입니다.
                                                                                                                                             
        이번 기수 커리큘럼 및 참고자료 링크를 공유드립니다.
        아래 링크를 참고해주세요!
        """,
        authorID: "author123",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -7200),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [],
        links: [
            "https://www.notion.so/umc-curriculum",
            "https://github.com/UMC-community"
        ],
        vote: nil
    )
    
    /// 이미지 + 링크 + 투표 전부 포함된 공지 샘플
    static let sampleNoticeWithAll = NoticeDetail(
        id: "5",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: false,
        title: "12기 OT 자료 및 단체사진 공유",
        content: """
        12기 OT에서 발표된 자료와 단체사진을 공유합니다.
                                                                                                                                             
        자료는 링크에서 확인하실 수 있습니다!
        """,
        authorID: "author123",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -14400),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [
            "https://picsum.photos/400/400",
            "https://picsum.photos/400/401",
            "https://picsum.photos/400/402"
        ],
        links: [
            "https://www.notion.so/umc-12th-ot"
        ],
        vote: NoticeVote(
            id: "poll-all-1",
            question: "OT 자료 중 가장 유용했던 세션은 무엇인가요?",
            options: [
                VoteOption(id: "1", title: "앱 아키텍처", voteCount: 18),
                VoteOption(id: "2", title: "협업/깃 전략", voteCount: 22),
                VoteOption(id: "3", title: "배포 프로세스", voteCount: 11),
                VoteOption(id: "4", title: "Q&A", voteCount: 7)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 4),
            allowMultipleChoices: false,
            isAnonymous: true,
            userVotedOptionIds: []
        )
    )
    
    /// 투표 미완료 상태 공지 샘플 (복수선택, 실명 투표)
    static let sampleNoticeWithVote = NoticeDetail(
        id: "6",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: true,
        title: "[투표] 다음 스터디 주제 선정",
        content: """
        다음 스터디 주제를 선정합니다.
                                                                                                                                             
        관심있는 주제에 투표해주세요!
        """,
        authorID: "author456",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -43200),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [],
        links: [],
        vote: NoticeVote(
            id: "poll2",
            question: "참여하고 싶은 스터디를 모두 선택해주세요",
            options: [
                VoteOption(id: "1", title: "알고리즘", voteCount: 12),
                VoteOption(id: "2", title: "CS 스터디", voteCount: 25),
                VoteOption(id: "3", title: "디자인 패턴", voteCount: 8),
                VoteOption(id: "4", title: "영어 회화", voteCount: 15)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 5),
            allowMultipleChoices: true,
            isAnonymous: false,
            userVotedOptionIds: []
        )
    )
    
    /// 투표 완료 상태 공지 샘플 (마감 + 사용자 투표 기록 포함)
    static let sampleNoticeWithVoteDone = NoticeDetail(
        id: "6",
        generation: 12,
        scope: .central,
        category: .general,
        isMustRead: true,
        title: "[투표] 다음 스터디 주제 선정",
        content: """
        다음 스터디 주제를 선정합니다.
                                                                                                                                             
        관심있는 주제에 투표해주세요!
        """,
        authorID: "author456",
        authorName: "쳇쳇/전채운-UMC 9th 총괄",
        authorImageURL: nil,
        createdAt: Date(timeIntervalSinceNow: -43200),
        updatedAt: nil,
        targetAudience: TargetAudience(
            generation: 12,
            scope: .central,
            parts: [],
            branches: [],
            schools: []
        ),
        hasPermission: false,
        images: [],
        links: [],
        vote: NoticeVote(
            id: "poll2",
            question: "참여하고 싶은 스터디를 모두 선택해주세요",
            options: [
                VoteOption(id: "1", title: "알고리즘", voteCount: 12),
                VoteOption(id: "2", title: "CS 스터디", voteCount: 25),
                VoteOption(id: "3", title: "디자인 패턴", voteCount: 8),
                VoteOption(id: "4", title: "영어 회화", voteCount: 15)
            ],
            startDate: Date(timeIntervalSinceNow: -86400 * 10),
            endDate: Date(timeIntervalSinceNow: -86400),
            allowMultipleChoices: true,
            isAnonymous: false,
            userVotedOptionIds: ["1", "2"]
        )
    )
    
    /// 전체 샘플 목록 (Preview, 디버그 용도)
    static let items: [NoticeDetail] = [
        sampleNotice,
        sampleNoticeWithPermission,
        sampleNoticeWithImages,
        sampleNoticeWithLinks,
        sampleNoticeWithAll,
        sampleNoticeWithVote,
        sampleNoticeWithVoteDone
    ]
    
    // MARK: - Read Status Mock

    /// 열람 현황 테스트용 사용자 목록
    static let sampleReadStatusUsers: [ReadStatusUser] = [
        ReadStatusUser(id: "user1", name: "정의찬", nickName: "제옹", part: "PM", branch: "Leo", campus: "중앙대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user2", name: "이재원", nickName: "리버", part: "iOS", branch: "Cassiopeia", campus: "한성대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user3", name: "김미주", nickName: "마티", part: "iOS", branch: "Cetus", campus: "덕성여대", profileImageURL: nil, isRead: false),
        ReadStatusUser(id: "user4", name: "이예지", nickName: "소피", part: "iOS", branch: "Nova", campus: "가천대", profileImageURL: nil, isRead: false),
        ReadStatusUser(id: "user5", name: "박경운", nickName: "하늘", part: "Spring Boot", branch: "Leo", campus: "중앙대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user6", name: "강하나", nickName: "와나", part: "Spring Boot", branch: "Cassiopeia", campus: "한양대 ERICA", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user7", name: "박지현", nickName: "박박지현", part: "Spring Boot", branch: "Scorpio", campus: "동국대", profileImageURL: nil, isRead: false),
        ReadStatusUser(id: "user8", name: "박세은", nickName: "세니", part: "Spring Boot", branch: "Leo", campus: "동덕여대", profileImageURL: nil, isRead: false),
        ReadStatusUser(id: "user9", name: "이예은", nickName: "스읍", part: "Spring Boot", branch: "Leo", campus: "중앙대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user10", name: "이희원", nickName: "삼이", part: "Design", branch: "Cetus", campus: "성신여대", profileImageURL: nil, isRead: false),
        ReadStatusUser(id: "user11", name: "박유수", nickName: "어헛차", part: "Android", branch: "Nova", campus: "숭실대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user12", name: "조경석", nickName: "조나단", part: "Android", branch: "Scorpio", campus: "명지대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user13", name: "양지애", nickName: "나루", part: "Android", branch: "Scorpio", campus: "서울여대", profileImageURL: nil, isRead: true),
        ReadStatusUser(id: "user14", name: "김도연", nickName: "도리", part: "Android", branch: "Scorpio", campus: "서울여대", profileImageURL: nil, isRead: false)
    ]
    
    /// 열람 현황 통합 샘플 (확인/미확인 사용자 자동 분류)
    static let sampleReadStatus = NoticeReadStatus(
        noticeId: "1",
        confirmedUsers: sampleReadStatusUsers.filter { $0.isRead },
        unconfirmedUsers: sampleReadStatusUsers.filter { !$0.isRead }
    )
}
