//
//  CommunityDebugScheme.swift
//  AppProduct
//
//  Created by 김미주 on 2/17/26.
//

import Foundation

#if DEBUG
enum CommunityDebugState: String {
    case loading
    case loaded
    case loadedAll
    case loadedQuestion
    case loadedLightning
    case failed

    static func fromLaunchArgument() -> CommunityDebugState? {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--community-loading") {
            return .loading
        }
        if arguments.contains("--community-loaded") {
            return .loadedAll
        }
        if arguments.contains("--community-failed") {
            return .failed
        }

        if let index = arguments.firstIndex(of: "-communityDebugState"),
           arguments.indices.contains(index + 1) {
            if arguments[index + 1] == CommunityDebugState.loaded.rawValue {
                return .loadedAll
            }
            return CommunityDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["COMMUNITY_DEBUG_STATE"] {
            if environmentValue == CommunityDebugState.loaded.rawValue {
                return .loadedAll
            }
            return CommunityDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: CommunityViewModel) {
        switch self {
        case .loading:
            viewModel.seedForDebugState(
                items: .loading,
                selectedMenu: .all
            )
        case .loaded:
            viewModel.seedForDebugState(
                items: .loaded(Self.allItems),
                selectedMenu: .all
            )
        case .loadedAll:
            viewModel.seedForDebugState(
                items: .loaded(Self.allItems),
                selectedMenu: .all
            )
        case .loadedQuestion:
            viewModel.seedForDebugState(
                items: .loaded(Self.questionItems),
                selectedMenu: .question
            )
        case .loadedLightning:
            viewModel.seedForDebugState(
                items: .loaded(Self.lightningItems),
                selectedMenu: .party
            )
        case .failed:
            viewModel.seedForDebugState(
                items: .failed(.unknown(message: "커뮤니티 게시글을 불러오지 못했습니다.")),
                selectedMenu: .all
            )
        }
    }

    private static var allItems: [CommunityItemModel] {
        [
            CommunityItemModel(
                postId: 1001,
                userId: 101,
                category: .question,
                title: "SwiftUI Navigation 관련 질문",
                content: "NavigationStack에서 경로 관리는 어떻게 하나요?",
                profileImage: nil,
                userName: "김철수",
                part: .front(type: .ios),
                createdAt: .now,
                likeCount: 12,
                commentCount: 5,
                scrapCount: 3,
                isLiked: false,
                isScrapped: false,
                isAuthor: false,
                lightningInfo: nil
            ),
            CommunityItemModel(
                postId: 1002,
                userId: 102,
                category: .lighting,
                title: "오늘 저녁 스터디 모임",
                content: "오늘 저녁 7시에 강남역에서 스터디 모임 합니다!",
                profileImage: nil,
                userName: "박영희",
                part: .front(type: .ios),
                createdAt: .now.addingTimeInterval(-3600),
                likeCount: 8,
                commentCount: 3,
                scrapCount: 5,
                isLiked: true,
                isScrapped: false,
                isAuthor: false,
                lightningInfo: CommunityLightningInfo(
                    meetAt: .now.addingTimeInterval(14400),
                    location: "강남역 2번 출구",
                    maxParticipants: 6,
                    openChatUrl: "https://open.kakao.com/o/example"
                )
            ),
            CommunityItemModel(
                postId: 1003,
                userId: 103,
                category: .free,
                title: "UMC 활동 후기",
                content: "UMC에서 활동하면서 많이 성장한 것 같아요!",
                profileImage: nil,
                userName: "이민수",
                part: .server(type: .spring),
                createdAt: .now.addingTimeInterval(-7200),
                likeCount: 25,
                commentCount: 10,
                scrapCount: 8,
                isLiked: false,
                isScrapped: true,
                isAuthor: true,
                lightningInfo: nil
            )
        ]
    }

    private static var questionItems: [CommunityItemModel] {
        [
            CommunityItemModel(
                postId: 2001,
                userId: 201,
                category: .question,
                title: "Combine vs AsyncAwait 무엇을 사용해야 할까요?",
                content: "비동기 처리에 대한 질문입니다.",
                profileImage: nil,
                userName: "최지훈",
                part: .front(type: .ios),
                createdAt: .now,
                likeCount: 15,
                commentCount: 8,
                scrapCount: 6,
                isLiked: false,
                isScrapped: false,
                isAuthor: false,
                lightningInfo: nil
            ),
            CommunityItemModel(
                postId: 2002,
                userId: 202,
                category: .question,
                title: "MVVM 패턴 적용 문의",
                content: "ViewModel에서 View를 참조하는 것이 맞나요?",
                profileImage: nil,
                userName: "강서연",
                part: .front(type: .ios),
                createdAt: .now.addingTimeInterval(-1800),
                likeCount: 10,
                commentCount: 6,
                scrapCount: 4,
                isLiked: true,
                isScrapped: false,
                isAuthor: false,
                lightningInfo: nil
            )
        ]
    }

    private static var lightningItems: [CommunityItemModel] {
        [
            CommunityItemModel(
                postId: 3001,
                userId: 301,
                category: .lighting,
                title: "내일 점심 같이 드실 분!",
                content: "홍대 근처에서 점심 먹을 사람 구합니다",
                profileImage: nil,
                userName: "정다은",
                part: .design,
                createdAt: .now,
                likeCount: 5,
                commentCount: 2,
                scrapCount: 1,
                isLiked: false,
                isScrapped: false,
                isAuthor: false,
                lightningInfo: CommunityLightningInfo(
                    meetAt: .now.addingTimeInterval(86400),
                    location: "홍대입구역 9번 출구",
                    maxParticipants: 4,
                    openChatUrl: "https://open.kakao.com/o/lunch"
                )
            ),
            CommunityItemModel(
                postId: 3002,
                userId: 302,
                category: .lighting,
                title: "주말 코딩 모각코",
                content: "이번 주말에 카페에서 모각코 하실 분?",
                profileImage: nil,
                userName: "윤서준",
                part: .front(type: .web),
                createdAt: .now.addingTimeInterval(-3600),
                likeCount: 12,
                commentCount: 7,
                scrapCount: 9,
                isLiked: true,
                isScrapped: true,
                isAuthor: false,
                lightningInfo: CommunityLightningInfo(
                    meetAt: .now.addingTimeInterval(172800),
                    location: "강남 스타벅스",
                    maxParticipants: 8,
                    openChatUrl: "https://open.kakao.com/o/study"
                )
            )
        ]
    }
}

// MARK: - Community Fame Debug State

enum CommunityFameDebugState: String {
    case loading
    case loaded
    case failed

    static func fromLaunchArgument() -> CommunityFameDebugState? {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--fame-loading") {
            return .loading
        }
        if arguments.contains("--fame-loaded") {
            return .loaded
        }
        if arguments.contains("--fame-failed") {
            return .failed
        }

        if let index = arguments.firstIndex(of: "-fameDebugState"),
           arguments.indices.contains(index + 1) {
            return CommunityFameDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["FAME_DEBUG_STATE"] {
            return CommunityFameDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: CommunityFameViewModel) {
        switch self {
        case .loading:
            viewModel.seedForDebugState(
                fameItems: .loading,
                selectedWeek: 1,
                selectedUniversity: "전체",
                selectedPart: "전체"
            )
        case .loaded:
            viewModel.seedForDebugState(
                fameItems: .loaded(Self.fameItems),
                selectedWeek: 1,
                selectedUniversity: "전체",
                selectedPart: "전체"
            )
        case .failed:
            viewModel.seedForDebugState(
                fameItems: .failed(.unknown(message: "명예의전당 목록을 불러오지 못했습니다.")),
                selectedWeek: 1,
                selectedUniversity: "전체",
                selectedPart: "전체"
            )
        }
    }

    private static var fameItems: [CommunityFameItemModel] {
        [
            CommunityFameItemModel(
                week: 1,
                university: "가천대학교",
                profileImage: nil,
                userName: "김민수",
                part: .front(type: .ios),
                workbookTitle: "SwiftUI 완벽 가이드",
                content: "SwiftUI의 기본 개념부터 고급 기술까지 상세히 정리했습니다."
            ),
            CommunityFameItemModel(
                week: 1,
                university: "가천대학교",
                profileImage: nil,
                userName: "박서연",
                part: .front(type: .android),
                workbookTitle: "Kotlin Coroutine 마스터하기",
                content: "비동기 처리의 모든 것을 담았습니다."
            ),
            CommunityFameItemModel(
                week: 1,
                university: "건국대학교",
                profileImage: nil,
                userName: "이지훈",
                part: .server(type: .spring),
                workbookTitle: "Spring Boot 실전 프로젝트",
                content: "RESTful API 설계와 구현 노하우를 공유합니다."
            ),
            CommunityFameItemModel(
                week: 1,
                university: "건국대학교",
                profileImage: nil,
                userName: "최유진",
                part: .front(type: .web),
                workbookTitle: "React 최적화 전략",
                content: "성능 최적화 기법들을 정리했습니다."
            ),
            CommunityFameItemModel(
                week: 1,
                university: "경희대학교",
                profileImage: nil,
                userName: "정다은",
                part: .design,
                workbookTitle: "UX/UI 디자인 원칙",
                content: "사용자 중심의 디자인 방법론을 다룹니다."
            ),
            CommunityFameItemModel(
                week: 2,
                university: "가천대학교",
                profileImage: nil,
                userName: "강서준",
                part: .server(type: .node),
                workbookTitle: "Node.js 백엔드 아키텍처",
                content: "확장 가능한 서버 구조 설계 방법입니다."
            )
        ]
    }
}
#endif
