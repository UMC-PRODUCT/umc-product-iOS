//
//  ManagementTeam.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import Foundation
import SwiftUI

/// UMC 운영진 직책 및 역할을 정의하는 열거형입니다.
///
/// 각 직책별로 표시될 텍스트(RawValue)와 고유한 색상(textColor, backgroundColor)을 제공합니다.
enum ManagementTeam: String, Equatable {
    /// 회장
    case president = "👑 회장"
    /// 부회장
    case vicePresident = "⭐️ 부회장"
    /// 지부장
    case branchLeader = "🏢 지부장"
    /// 중앙운영사무국
    case centralOffice = "🏛️ 중앙운영사무국"
    /// 파트장
    case partLeader = "🚩 파트장"
    /// 일반 챌린저
    case challenger = "챌린저"

    /// 각 직책에 해당하는 고유 텍스트 색상을 반환합니다.
    var textColor: Color {
        switch self {
        case .president: return .red        // 회장: 빨간색
        case .vicePresident: return .orange // 부회장: 주황색
        case .branchLeader: return .purple  // 지부장: 보라색
        case .centralOffice: return .blue   // 중운위: 파란색
        case .partLeader: return .cyan      // 파트장: 청록색
        case .challenger: return .clear     // 챌린저: 투명 (또는 기본색)
        }
    }

    /// 각 직책 배경색을 반환합니다.
    /// 텍스트 색상에 투명도(0.3)를 적용하여 은은한 배경색을 생성합니다.
    var backgroundColor: Color {
        textColor.opacity(0.3)
    }
}
