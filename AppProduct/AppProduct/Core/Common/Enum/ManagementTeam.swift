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
/// 서버 API `roleType` 값과 1:1 매핑됩니다.
///
/// 계층 구조 (높은 → 낮은)
/// 1. superAdmin (시스템 관리자)
/// 2. centralPresident / centralVicePresident (총괄/부총괄)
/// 3. centralOperatingTeamMember / centralEducationTeamMember (중앙 운영진)
/// 4. chapterPresident (지부장)
/// 5. schoolPresident / schoolVicePresident (교내 회장단)
/// 6. schoolPartLeader (교내 파트장)
/// 7. schoolEtcAdmin (교내 기타 운영진)
/// 8. challenger (챌린저)
enum ManagementTeam: String, CaseIterable, Codable, Comparable {

    // MARK: - Cases

    case superAdmin = "SUPER_ADMIN"
    case centralPresident = "CENTRAL_PRESIDENT"
    case centralVicePresident = "CENTRAL_VICE_PRESIDENT"
    case centralOperatingTeamMember = "CENTRAL_OPERATING_TEAM_MEMBER"
    case centralEducationTeamMember = "CENTRAL_EDUCATION_TEAM_MEMBER"
    case chapterPresident = "CHAPTER_PRESIDENT"
    case schoolPresident = "SCHOOL_PRESIDENT"
    case schoolVicePresident = "SCHOOL_VICE_PRESIDENT"
    case schoolPartLeader = "SCHOOL_PART_LEADER"
    case schoolEtcAdmin = "SCHOOL_ETC_ADMIN"
    case challenger = "CHALLENGER"

    // MARK: - Level

    /// 권한 레벨 (높을수록 상위 권한)
    var level: Int {
        switch self {
        case .superAdmin:                   return 100
        case .centralPresident:             return 90
        case .centralVicePresident:         return 85
        case .centralOperatingTeamMember:   return 80
        case .centralEducationTeamMember:   return 80
        case .chapterPresident:             return 70
        case .schoolPresident:              return 60
        case .schoolVicePresident:          return 55
        case .schoolPartLeader:             return 40
        case .schoolEtcAdmin:              return 30
        case .challenger:                   return 0
        }
    }

    /// Admin 모드 접근 가능 여부
    var canAccessAdminMode: Bool {
        level >= Self.schoolEtcAdmin.level
    }

    // MARK: - Comparable

    static func < (lhs: ManagementTeam, rhs: ManagementTeam) -> Bool {
        lhs.level < rhs.level
    }

    // MARK: - Display

    /// 한글 표시명
    var korean: String {
        switch self {
        case .superAdmin:                   return "시스템 관리자"
        case .centralPresident:             return "총괄"
        case .centralVicePresident:         return "부총괄"
        case .centralOperatingTeamMember:   return "중앙 운영 사무국"
        case .centralEducationTeamMember:   return "중앙 운영 교육국"
        case .chapterPresident:             return "지부장"
        case .schoolPresident:              return "교내 회장"
        case .schoolVicePresident:          return "교내 부회장"
        case .schoolPartLeader:             return "교내 파트장"
        case .schoolEtcAdmin:              return "교내 운영진"
        case .challenger:                   return "챌린저"
        }
    }

    // MARK: - UI Styling

    /// 배지 아이콘
    var icon: String {
        switch self {
        case .superAdmin:                                           return "👑"
        case .centralPresident, .centralVicePresident:               return "⭐️"
        case .centralOperatingTeamMember, .centralEducationTeamMember: return "⭐️"
        case .chapterPresident:                                     return "🏛️"
        case .schoolPresident, .schoolVicePresident:                 return "🏫"
        case .schoolPartLeader, .schoolEtcAdmin:                    return "🚩"
        case .challenger:                                           return ""
        }
    }

    /// 아이콘 포함 표시명
    var displayName: String {
        icon.isEmpty ? korean : "\(icon) \(korean)"
    }

    var textColor: Color {
        switch self {
        case .superAdmin:
            return .red100
        case .centralPresident, .centralVicePresident,
             .centralOperatingTeamMember, .centralEducationTeamMember:
            return .indigo100
        case .chapterPresident, .schoolPresident, .schoolVicePresident:
            return .orange500
        case .schoolPartLeader, .schoolEtcAdmin:
            return .green500
        case .challenger:
            return .clear
        }
    }

    var backgroundColor: Color {
        switch self {
        case .superAdmin:
            return .red300
        case .centralPresident, .centralVicePresident,
             .centralOperatingTeamMember, .centralEducationTeamMember:
            return .indigo400
        case .chapterPresident, .schoolPresident, .schoolVicePresident:
            return .orange100
        case .schoolPartLeader, .schoolEtcAdmin:
            return .green100
        case .challenger:
            return .clear
        }
    }

    var borderColor: Color {
        switch self {
        case .superAdmin:
            return .red500
        case .centralPresident, .centralVicePresident,
             .centralOperatingTeamMember, .centralEducationTeamMember:
            return .indigo700
        case .chapterPresident, .schoolPresident, .schoolVicePresident:
            return .orange300
        case .schoolPartLeader, .schoolEtcAdmin:
            return .green300
        case .challenger:
            return .clear
        }
    }
}
