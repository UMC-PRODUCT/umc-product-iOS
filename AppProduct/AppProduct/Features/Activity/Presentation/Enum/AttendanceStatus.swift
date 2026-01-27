//
//  AttendanceStatus.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation
import SwiftUI

enum AttendanceStatus: String, CaseIterable {
    // rawValue는 API 호환성을 위해 기존값 유지
    case beforeAttendance = "pending"  // 출석 전
    case pendingApproval               // 승인 대기
    case present                       // 출석
    case late                          // 지각
    case absent                        // 결석

    /// 배지/버튼에 표시할 텍스트
    var displayText: String {
        switch self {
        case .beforeAttendance:
            return "출석 전"
        case .pendingApproval:
            return "승인 대기"
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
        case .beforeAttendance:
            return .gray.opacity(0.7)
        case .pendingApproval:
            return .yellow.opacity(0.7)
        case .present:
            return .green.opacity(0.7)
        case .late:
            return .yellow.opacity(0.7)
        case .absent:
            return .red.opacity(0.7)
        }
    }

    var fontColor: Color {
        switch self {
        default:
            return .white
        }
    }
}
