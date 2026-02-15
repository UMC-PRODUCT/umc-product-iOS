//
//  MyPageMockData.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

#if DEBUG
enum MyPageMockData {
    static let profile = ProfileData(
        challengeId: 269,
        challangerInfo: ChallengerInfo(
            memberId: 1001,
            gen: 8,
            name: "홍길동",
            nickname: "길동",
            schoolName: "한성대학교",
            profileImage: nil,
            part: .front(type: .ios)
        ),
        socialConnected: [.kakao, .apple],
        activityLogs: [
            .init(
                part: .front(type: .ios),
                generation: 8,
                role: .challenger
            ),
            .init(
                part: .server(type: .spring),
                generation: 7,
                role: .schoolPartLeader
            ),
            .init(
                part: .design,
                generation: 6,
                role: .schoolPresident
            )
        ],
        profileLink: [
            .init(type: .github, url: "https://github.com/euijjang97"),
            .init(type: .linkedin, url: "https://linkedin.com/in/euijjang97"),
            .init(type: .blog, url: "https://velog.io/@euijjang97")
        ]
    )

    static let posts: [CommunityItemModel] = [
        .init(
            userId: 1001,
            category: .hobby,
            title: "스터디원 모집합니다",
            content: "Spring Boot 스터디원 모집합니다.",
            profileImage: nil,
            userName: "홍길동",
            part: "iOS",
            createdAt: "2시간 전",
            likeCount: 42,
            commentCount: 5,
            isLiked: true
        ),
        .init(
            userId: 1001,
            category: .question,
            title: "SwiftUI 네비게이션 질문",
            content: "NavigationStack 경로 분리 패턴을 어떻게 관리하시나요?",
            profileImage: nil,
            userName: "홍길동",
            part: "iOS",
            createdAt: "1일 전",
            likeCount: 13,
            commentCount: 4,
            isLiked: false
        ),
        .init(
            userId: 1001,
            category: .impromptu,
            title: "번개: 강남역 커피챗",
            content: "iOS 아키텍처 얘기하실 분 모집합니다.",
            profileImage: nil,
            userName: "홍길동",
            part: "iOS",
            createdAt: "3일 전",
            likeCount: 7,
            commentCount: 1,
            isLiked: true
        )
    ]

    static func page(query: MyPagePostListQuery) -> MyActivePostPage {
        MyActivePostPage(
            items: posts,
            page: query.page,
            hasNext: false
        )
    }

    static func terms(for termsType: String) -> MyPageTerms {
        switch termsType.uppercased() {
        case "PRIVACY":
            return MyPageTerms(
                id: "11",
                link: "https://makeus-challenge.notion.site/privacy",
                isMandatory: true
            )
        case "SERVICE":
            return MyPageTerms(
                id: "10",
                link: "https://makeus-challenge.notion.site/service",
                isMandatory: true
            )
        default:
            return MyPageTerms(
                id: "0",
                link: "https://makeus-challenge.notion.site/",
                isMandatory: false
            )
        }
    }
}
#endif
