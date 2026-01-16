//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    var items: [CommunityItemModel] = [
        .init(category: .impromptu, tag: .cheerUp, title: "오늘 강남역 카공하실 분?", content: "오후 2시부터 6시까지 강남역 근처 카페에서 각자 할일 하실 분 구합니다! 현재 2명 있어요.", profileImage: nil, userName: "김멋사", part: "iOS", createdAt: "방금 전", likeCount: 2, commentCount: 1),
        .init(category: .question, tag: .feedback, title: "React Hook 질문있습니다", content: "useEffect 의존성 배열 관련해서 질문이 있습니다... 코드가 자꾸 무한 루프에 빠지는데 로직 점검 부탁드려요!", profileImage: nil, userName: "이코딩", part: "Web", createdAt: "1시간 전", likeCount: 5, commentCount: 3),
        .init(category: .impromptu, tag: .cheerUp, title: "오늘 강남역 카공하실 분?", content: "오후 2시부터 6시까지 강남역 근처 카페에서 각자 할일 하실 분 구합니다! 현재 2명 있어요.", profileImage: nil, userName: "김멋사", part: "iOS", createdAt: "방금 전", likeCount: 2, commentCount: 1),
        .init(category: .question, tag: .feedback, title: "React Hook 질문있습니다", content: "useEffect 의존성 배열 관련해서 질문이 있습니다... 코드가 자꾸 무한 루프에 빠지는데 로직 점검 부탁드려요!", profileImage: nil, userName: "이코딩", part: "Web", createdAt: "1시간 전", likeCount: 5, commentCount: 3),
        .init(category: .impromptu, tag: .cheerUp, title: "오늘 강남역 카공하실 분?", content: "오후 2시부터 6시까지 강남역 근처 카페에서 각자 할일 하실 분 구합니다! 현재 2명 있어요.", profileImage: nil, userName: "김멋사", part: "iOS", createdAt: "방금 전", likeCount: 2, commentCount: 1),
        .init(category: .question, tag: .feedback, title: "React Hook 질문있습니다", content: "useEffect 의존성 배열 관련해서 질문이 있습니다... 코드가 자꾸 무한 루프에 빠지는데 로직 점검 부탁드려요!", profileImage: nil, userName: "이코딩", part: "Web", createdAt: "1시간 전", likeCount: 5, commentCount: 3),
    ]
}
