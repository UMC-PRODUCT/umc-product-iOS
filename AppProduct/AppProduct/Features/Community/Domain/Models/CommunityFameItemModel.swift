//
//  CommunityFameItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

struct CommunityFameItemModel: Equatable, Identifiable {
    let id = UUID()
    let profileImage: Image?
    let userName: String
    let part: String
    let workbookTitle: String
    let content: String
}
