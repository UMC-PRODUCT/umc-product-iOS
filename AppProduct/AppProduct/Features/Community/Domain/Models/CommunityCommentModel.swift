//
//  CommunityCommentModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityCommentModel: Equatable, Identifiable {
    let id = UUID()
    let profileImage: Image?
    let userName: String
    let content: String
    let createdAt: String
}
