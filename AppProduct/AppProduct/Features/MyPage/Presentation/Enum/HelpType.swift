//
//  HelpType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import Foundation
import SwiftUI

/// 마이페이지 고객지원 타입
///
/// 사용자가 UMC 운영진에게 문의할 수 있는 채널을 정의합니다.
enum HelpType: String, CaseIterable {
    /// UMC 카카오톡 채널 문의
    case inquery = "UMC 카카오톡 문의"

    /// SF Symbols 아이콘 이름
    ///
    /// - Returns: SF Symbols 아이콘 문자열
    var icon: String {
        switch self {
        case .inquery:
            return "questionmark.circle.fill"
        }
    }

    /// 아이콘 배경 색상
    ///
    /// - Returns: SwiftUI Color
    var color: Color {
        switch self {
        case .inquery:
            return .yellow
        }
    }
}
