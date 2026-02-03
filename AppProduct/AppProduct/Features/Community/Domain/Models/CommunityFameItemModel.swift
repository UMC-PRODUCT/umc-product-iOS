//
//  CommunityFameItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

struct CommunityFameItemModel: Equatable, Identifiable {
    let id = UUID()
    let week: Int
    let university: String
    let profileImage: String?
    let userName: String
    let part: UMCPartType
    let workbookTitle: String
    let content: String
}
