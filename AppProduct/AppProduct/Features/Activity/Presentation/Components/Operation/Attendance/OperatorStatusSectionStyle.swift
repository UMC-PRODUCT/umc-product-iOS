//
//  OperatorStatusSectionStyle.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/6/26.
//

import SwiftUI

/// 운영진 세션 카드 상태 섹션 스타일
///
/// 세션 진행 상태에 따른 하단 상태 섹션의 아이콘, 텍스트, 색상을 정의합니다.
enum OperatorStatusSectionStyle {
    case beforeStart
    case pending
    case inProgress
    case complete

    // MARK: - Property

    var icon: String {
        switch self {
        case .beforeStart: "hourglass.badge.lock"
        case .pending: "person.2.fill"
        case .inProgress: "clock.fill"
        case .complete: "checkmark.circle.fill"
        }
    }

    var text: String {
        switch self {
        case .beforeStart: "세션이 아직 시작되지 않았습니다."
        case .pending: "승인 대기 명단 확인하기"
        case .inProgress: "현재 승인 대기가 없습니다."
        case .complete: "모든 출석 승인이 완료되었습니다."
        }
    }

    var color: Color {
        switch self {
        case .beforeStart: .gray
        case .pending: .orange
        case .inProgress: .indigo500
        case .complete: .green
        }
    }

    var backgroundColor: Color {
        switch self {
        case .beforeStart: .grey200
        case .pending: .orange.opacity(0.15)
        case .inProgress: .indigo100
        case .complete: .green.opacity(0.15)
        }
    }

    /// pending만 활성화, 나머지는 disabled
    var isEnabled: Bool {
        self == .pending
    }

    /// pending만 chevron 표시
    var showChevron: Bool {
        self == .pending
    }
}
