//
//  ActivitySection.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import Foundation

/// Activity 화면의 섹션
enum ActivitySection: String, Identifiable, CaseIterable {
    // MARK: - Challenger 섹션
    case attendanceCheck = "출석 체크"
    case studyActivity = "스터디/활동"
    case members = "구성원"

    // MARK: - Admin 섹션
    case attendanceManage = "출석 관리"
    case studyManage = "스터디 관리"
    case memberManage = "멤버 관리"

    var id: Self { self }

    var icon: String {
        switch self {
        case .attendanceCheck, .attendanceManage:
            return "checkmark.circle"
        case .studyActivity, .studyManage:
            return "book.pages"
        case .members, .memberManage:
            return "person.3"
        }
    }

    /// 모드별 사용 가능한 섹션 목록
    static func sections(for mode: ActivityMode) -> [ActivitySection] {
        switch mode {
        case .challenger:
            [.attendanceCheck, .studyActivity, .members]
        case .admin:
            [.attendanceManage, .studyManage, .memberManage]
        }
    }

    /// 모드별 기본 선택 섹션
    static func defaultSection(for mode: ActivityMode) -> ActivitySection {
        switch mode {
        case .challenger:
            .attendanceCheck
        case .admin:
            .attendanceManage
        }
    }

    /// 다른 모드에서 의미상 대응되는 섹션을 반환합니다.
    func mapped(to mode: ActivityMode) -> ActivitySection {
        switch mode {
        case .challenger:
            switch self {
            case .attendanceCheck, .attendanceManage:
                return .attendanceCheck
            case .studyActivity, .studyManage:
                return .studyActivity
            case .members, .memberManage:
                return .members
            }
        case .admin:
            switch self {
            case .attendanceCheck, .attendanceManage:
                return .attendanceManage
            case .studyActivity, .studyManage:
                return .studyManage
            case .members, .memberManage:
                return .memberManage
            }
        }
    }
}
