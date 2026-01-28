//
//  ManagementTeam.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/25/26.
//

import Foundation
import SwiftUI

/// 멤버 역할/권한 구분
///
/// 계층 구조 (높은 → 낮은)
/// 1. general (총괄단) - 최고 관리자
/// 2. centralOperator (중앙운영진)
/// 3. campusPresident (교내회장단)
/// 4. campusPartLeader (교내파트장)
/// 5. challenger (챌린저)
///
/// - Note: 추후 역할 추가 시 case와 level만 조정하면 됩니다.
enum ManagementTeam: String, CaseIterable, Comparable {

    // MARK: - Cases

    case general = "총괄단"
    case centralOperator = "중앙운영진"
    case campusPresident = "교내회장단"
    case campusPartLeader = "교내파트장"
    case challenger = "챌린저"

    // MARK: - Level (확장성)

    /// 권한 레벨 (높을수록 상위 권한)
    var level: Int {
        switch self {
        case .general: return 100
        case .centralOperator: return 80
        case .campusPresident: return 60
        case .campusPartLeader: return 40
        case .challenger: return 0
        }
    }

    /// Admin 모드 접근 가능 여부
    var canAccessAdminMode: Bool {
        level >= Self.campusPartLeader.level
    }

    // MARK: - Comparable

    /// 두 역할의 권한 레벨을 비교합니다.
    ///
    /// - Parameters:
    ///   - lhs: 비교할 첫 번째 역할
    ///   - rhs: 비교할 두 번째 역할
    /// - Returns: lhs의 권한이 rhs보다 낮으면 true
    static func < (lhs: ManagementTeam, rhs: ManagementTeam) -> Bool {
        lhs.level < rhs.level
    }

    // MARK: - UI Styling

    /// 배지 아이콘
    var icon: String {
        switch self {
        case .general: return "👑"
        case .centralOperator: return "⭐️"
        case .campusPresident: return "🏫"
        case .campusPartLeader: return "🚩"
        case .challenger: return ""
        }
    }

    /// 아이콘 포함 표시명
    var displayName: String {
        icon.isEmpty ? rawValue : "\(icon) \(rawValue)"
    }

    var textColor: Color {
        switch self {
        case .general: return .red100
        case .centralOperator: return .indigo100
        case .campusPresident: return .orange500
        case .campusPartLeader: return .green500
        case .challenger: return .clear
        }
    }

    var backgroundColor: Color {
        switch self {
        case .general: return .red300
        case .centralOperator: return .indigo400
        case .campusPresident: return .orange100
        case .campusPartLeader: return .green100
        case .challenger: return .clear
        }
    }

    var borderColor: Color {
        switch self {
        case .general: return .red500
        case .centralOperator: return .indigo700
        case .campusPresident: return .orange300
        case .campusPartLeader: return .green300
        case .challenger: return .clear
        }
    }
}
