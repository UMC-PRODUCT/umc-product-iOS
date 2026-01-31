//
//  MissionStatus.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/29/26.
//

import Foundation
import SwiftUI

/// 미션 상태
enum MissionStatus: String, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case pendingApproval = "대기중"
    case pass = "Pass"
    case fail = "Fail"
    case locked = "Locked"

    var displayText: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .notStarted: return .gray.opacity(0.4)
        case .inProgress: return .indigo200
        case .pendingApproval: return Color.yellow.opacity(0.4)
        case .pass: return .green.opacity(0.4)
        case .fail: return Color.red.opacity(0.4)
        case .locked: return .grey200
        }
    }
    
    var missionListIconColor: Color {
        switch self {
        case .notStarted: return .gray.opacity(0.7)
        case .inProgress: return .indigo400
        case .pendingApproval: return .orange.opacity(0.7)
        case .pass: return .green.opacity(0.7)
        case .fail: return Color.red.opacity(0.7)
        case .locked: return .grey400
        }
    }

    var foregroundColor: Color {
        switch self {
        case .notStarted: return .grey600
        case .inProgress: return .indigo500
        case .pendingApproval: return .orange
        case .pass: return .green700
        case .fail: return .red
        case .locked: return .grey400
        }
    }

    var hasBorder: Bool {
        self == .inProgress
    }
}
