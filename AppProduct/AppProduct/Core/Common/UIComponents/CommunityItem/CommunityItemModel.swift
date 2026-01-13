//
//  CommunityItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

struct CommunityItemModel: Equatable, Identifiable {
    let id = UUID()
    let tag: CommunityItemTag
    let status: CommunityItemStatus
    let title: String
    let content: String
    let profileImage: Image?
    let userName: String
    let part: String
    let createdAt: String
    let likeCount: Int
    let commentCount: Int
}
