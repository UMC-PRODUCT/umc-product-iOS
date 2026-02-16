//
//  CommunityItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

struct CommunityItemModel: Equatable, Identifiable, Hashable {
    let id = UUID()
    let postId: Int
    let userId: Int
    let category: CommunityItemCategory
    let title: String
    let content: String
    let profileImage: String?
    let userName: String
    let part: UMCPartType
    let createdAt: Date
    var likeCount: Int
    let commentCount: Int
    var scrapCount: Int
    var isLiked: Bool = false
    var isScrapped: Bool = false
    let lightningInfo: CommunityLightningInfo?
}
