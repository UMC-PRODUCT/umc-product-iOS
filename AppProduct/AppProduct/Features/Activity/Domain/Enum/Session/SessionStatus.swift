//
//  SessionStatus.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import Foundation
import SwiftUI

/// 운영진 세션 진행 상태
enum OperatorSessionStatus: String, CaseIterable {
    case beforeStart = "진행전"
    case inProgress = "진행중"
    case ended = "종료됨"

    // MARK: - Property

    var displayText: String { rawValue }

    /// 상태 아이콘 색상
    var iconColor: Color {
        switch self {
        case .beforeStart: return .gray.opacity(0.7)
        case .inProgress: return .indigo400
        case .ended: return .green.opacity(0.7)
        }
    }

    /// 상태 텍스트 색상
    var textColor: Color {
        switch self {
        case .beforeStart: return .grey600
        case .inProgress: return .indigo500
        case .ended: return .gray
        }
    }

    // MARK: - Factory Method

    /// 시작/종료 시간으로부터 현재 상태 계산
    static func from(startTime: Date, endTime: Date, now: Date = Date()) -> OperatorSessionStatus {
        if now < startTime {
            return .beforeStart
        } else if now >= startTime && now <= endTime {
            return .inProgress
        } else {
            return .ended
        }
    }
}
