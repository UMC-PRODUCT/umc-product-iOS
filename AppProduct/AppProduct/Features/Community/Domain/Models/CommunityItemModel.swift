//
//  CommunityItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

struct CommunityItemModel: Equatable, Identifiable, Hashable {
    let id = UUID()
    let userId: Int
    let category: CommunityItemCategory
    let title: String
    let content: String
    let profileImage: String?
    let userName: String
    let part: UMCPartType
    let createdAt: Date
    let likeCount: Int
    let commentCount: Int
    let scrapCount: Int
    var isLiked: Bool = false
    var isScrapped: Bool = false
}
