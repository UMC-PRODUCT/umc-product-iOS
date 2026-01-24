//
//  ChipButtonStyle.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import Foundation

import SwiftUI

// MARK: - ChipButtonStyle
/// ChipButton 사이즈 유형
enum ChipButtonStyle {
    // 공지 리스트 필터(전체, 중앙운영사무국, 지부, 학교)
    case filter
    
    // 공지 작성: 게시판 분류(전체, 운영진 공지, 파트, 학교)
    case board
    
    
    func textColor(isSelected: Bool) -> Color {
        switch self {
        case .filter:
            return isSelected ? .grey000 : .grey600
        case .board:
            return .grey000
        }
    }
    
    func bgColor(isSelected: Bool) -> Color {
        switch self {
        case .filter:
            return isSelected ? .indigo500 : .grey200
        case .board:
            return isSelected ? .indigo500 : .grey300
        }
    }
}
