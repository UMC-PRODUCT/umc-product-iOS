//
//  MockCommunityRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/3/26.
//

import Foundation

#if DEBUG
/// 커뮤니티 Mock Repository

final class MockCommunityRepository: CommunityRepositoryProtocol {
    // MARK: - Properties
    
    private let mockFameItems: [CommunityFameItemModel]
    private let mockCommunityItems: [CommunityItemModel]
    
    // MARK: - Init
    init(
        mockFameItems: [CommunityFameItemModel]? = nil,
        mockCommunityItems: [CommunityItemModel]? = nil
    ) {
        self.mockFameItems = mockFameItems ?? Self.defaultMockFameItems
        self.mockCommunityItems = mockCommunityItems ?? Self.defaultMockCommunityItems
    }
    
    // MARK: - CommunityRepositoryProtocol
    func fetchFameItems() async throws -> [CommunityFameItemModel] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockFameItems
    }
    
    func fetchCommunityItems() async throws -> [CommunityItemModel] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockCommunityItems
    }
    
    func createPost(request: CreatePostRequest) async throws -> CommunityItemModel {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return CommunityItemModel(
            userId: 100,
            category: request.category,
            title: request.title,
            content: request.content,
            profileImage: nil,
            userName: "사용자",
            part: "iOS",
            createdAt: "방금 전",
            likeCount: 0,
            commentCount: 0
        )
    }
}

// MARK: - Mock Data

extension MockCommunityRepository {
    
    static let defaultMockFameItems: [CommunityFameItemModel] = [
        // 1주차
        .init(
            week: 1,
            university: "중앙대학교",
            profileImage: nil,
            userName: "김멋사",
            part: "Web",
            workbookTitle: "Web 1주차",
            content: "컴포넌트 분리가 매우 잘 되어있고, 상태 관리가 깔끔합니다."
        ),
        .init(
            week: 1,
            university: "명지대학교",
            profileImage: nil,
            userName: "이서버",
            part: "Server",
            workbookTitle: "Server 1주차",
            content: "RESTful 원칙을 잘 준수하였으며 예외 처리가 훌륭합니다."
        ),
        // 2주차
        .init(
            week: 2,
            university: "중앙대학교",
            profileImage: nil,
            userName: "이서버",
            part: "Server",
            workbookTitle: "Server 2주차",
            content: "의존성 주입 패턴을 잘 활용했습니다."
        ),
       .init(
           week: 2,
           university: "덕성여자대학교",
           profileImage: nil,
           userName: "최코딩",
           part: "Web",
           workbookTitle: "Web 2주차",
           content: "타입 정의가 명확하고 코드가 깔끔합니다."
       ),
       // 3주차
       .init(
           week: 3,
           university: "중앙대학교",
           profileImage: nil,
           userName: "김애플",
           part: "iOS",
           workbookTitle: "iOS 3주차",
           content: "MVVM 패턴을 잘 적용했습니다."
       ),
       .init(
           week: 3,
           university: "명지대학교",
           profileImage: nil,
           userName: "박서버",
           part: "Android",
           workbookTitle: "Android 3주차",
           content: "Compose 활용이 인상적입니다."
       ),
       // 4주차
       .init(
           week: 4,
           university: "중앙대학교",
           profileImage: nil,
           userName: "김멋사",
           part: "Web",
           workbookTitle: "Web 4주차",
           content: "상태 관리 라이브러리 활용이 뛰어납니다."
       ),
    ]
    
    static let defaultMockCommunityItems: [CommunityItemModel] = [
        .init(
            userId: 1,
            category: .question,
            title: "Swift 질문 있습니다",
            content: "Optional Binding에 대해 설명해주실 수 있나요?",
            profileImage: nil,
            userName: "김서버",
            part: "Server",
            createdAt: "방금 전",
            likeCount: 5,
            commentCount: 3
        ),
        .init(
            userId: 2,
            category: .hobby,
            title: "같이 운동하실 분 구합니다",
            content: "헬스장 같이 다니실 분 구합니다!",
            profileImage: nil,
            userName: "박웹",
            part: "Web",
            createdAt: "10분 전",
            likeCount: 12,
            commentCount: 8
        ),
        .init(
            userId: 3,
            category: .impromptu,
            title: "오늘 저녁 번개 모임",
            content: "7시에 홍대입구역에서 만나요!",
            profileImage: nil,
            userName: "이안드",
            part: "Android",
            createdAt: "1시간 전",
            likeCount: 23,
            commentCount: 15
        ),
    ]
}

#endif
