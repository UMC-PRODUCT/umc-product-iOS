//
//  RecentCategory.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation
import SwiftUI

/// 최근 공지사항의 카테고리를 정의
/// 최근 공지사항의 카테고리를 정의
///
/// 공지사항의 출처(운영진, 학교, 지부)를 구분하고
/// 각 카테고리에 맞는 아이콘과 색상을 제공합니다.
enum RecentCategory: String, CaseIterable {
    /// 운영진 공지 (중앙운영사무국)
    case operationsTeam = "중앙운영사무국"
    /// 학교(대학) 공지
    case univ = "학교"
    /// 지부 공지
    case oranization = "지부"
    
    /// 카테고리별 시스템 아이콘 이름
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
    
    /// 카테고리별 테마 색상 (배경 또는 아이콘 색상으로 사용)
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
