//
//  MyAttendanceItemStatus.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - MyAttendanceItemStatus

enum MyAttendanceItemStatus: Equatable {
    case pendingApproval
    case present
    case late
    case absent

    // MARK: - Properties

    var text: String {
        switch self {
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
        case .pendingApproval:
            return .black
        default:
            return .white
        }
    }
}

// MARK: - AttendanceStatus Conversion

extension MyAttendanceItemStatus {
    /// AttendanceStatus에서 변환
    /// - Note: beforeAttendance 상태는 nil 반환 (리스트에 표시 안함)
    init?(from status: AttendanceStatus) {
        switch status {
        case .pendingApproval:
            self = .pendingApproval
        case .present:
            self = .present
        case .late:
            self = .late
        case .absent:
            self = .absent
        case .beforeAttendance:
            return nil
        }
    }
}
