//
//  CommunityDetailViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import Foundation

@Observable
class CommunityDetailViewModel {
    var item: CommunityItemModel = .init(category: .impromptu, tag: .cheerUp, title: "오늘 강남역 카공하실 분?", content: "오후 2시부터 6시까지 강남역 근처 카페에서 각자 할일 하실 분 구합니다! 현재 2명 있어요.", profileImage: nil, userName: "김멋사", part: "iOS", createdAt: "방금 전", likeCount: 2, commentCount: 1)
}
