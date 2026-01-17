//
//  AttendanceStatus.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation
import SwiftUI

enum AttendanceStatus: String, CaseIterable {
    case pending
    case present
    case late
    case absent

    /// 배지/버튼에 표시할 텍스트
    var displayText: String {
        switch self {
        case .pending:
            return "출석 전"
        case .present:
            return "출석"
        case .late:
            return "지각"
        case .absent:
            return "결석"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pending: .grey200
        case .present: .green500
        case .late: .yellow500
        case .absent: .red500
        }
    }
    
    var fontColor: Color {
        switch self {
        case .pending: return .grey900
        case .present, .late, .absent:
            return .grey000
        }
    }
}
