//
//  CommunityItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import Foundation

struct CommunityItemModel: Equatable, Identifiable {
    let id = UUID()
    let tag: CommunityItemTag
    let status: CommunityItemStatus
    let title: String
    let location: String
    let userName: String
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
}
