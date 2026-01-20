//
//  RecentCategory.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation
import SwiftUI

/// 최근 공지사항의 카테고리를 정의
enum RecentCategory: String, CaseIterable {
    /// 운영진 공지
    case operationsTeam = "중앙운영사무국"
    /// 학교(대학) 공지
    case univ = "학교"
    /// 지부 공지
    case oranization = "지부"
    
    var icon: String {
        switch self {
        case .operationsTeam:
            return "megaphone.fill"
        case .univ:
            return "graduationcap.fill"
        case .oranization:
            return "network"
        }
    }
    
    var color: Color {
        switch self {
        case .operationsTeam:
            return .blue
        case .univ:
            return .teal
        case .oranization:
            return .purple
        }
    }
}
