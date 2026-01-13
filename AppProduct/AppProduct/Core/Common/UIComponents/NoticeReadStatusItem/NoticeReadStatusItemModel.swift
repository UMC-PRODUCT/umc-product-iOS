//
//  NoticeReadStatusItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

struct NoticeReadStatusItemModel: Equatable, Identifiable {
    let id = UUID()
    let profileImage: Image?
    let userName: String
    let part: String
    let location: String
    let campus: String
    let isRead: Bool
}
