//
//  TabCase.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation
import SwiftUI

enum TabCase: CaseIterable, Identifiable {
    case home
    case notice
    case activity
    case community
    case mypage
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .home:
            return "홈"
        case .notice:
            return "공지"
        case .activity:
            return "활동"
        case .community:
            return "커뮤니티"
        case .mypage:
            return "마이페이지"
        }
    }
    
    var icon: Image {
        switch self {
        case .home:
            Image(systemName: "house")
        case .notice:
            Image(systemName: "list.bullet.clipboard")
        case .activity:
            Image(systemName: "folder.badge.person.crop")
        case .community:
            Image(systemName: "bubble.left.and.bubble.right")
        case .mypage:
            Image(systemName: "person.fill")
        }
    }
    
    var tabRoloe: TabRole? {
        switch self {
        case .mypage:
            return .search
        default:
            return .none
        }
    }
}
