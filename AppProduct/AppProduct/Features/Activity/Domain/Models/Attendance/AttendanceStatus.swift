//
//  AttendanceStatus.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

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
}
