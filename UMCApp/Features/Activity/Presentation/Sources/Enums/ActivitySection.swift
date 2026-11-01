//
//  ActivitySection.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 8/3/26.
//

import CoreDomain
import Foundation

/// Activity 탭 루트가 노출하는 섹션
///
/// 챌린저는 출석·구성원, 운영진은 출석·스터디·멤버 관리 섹션을 제공한다.
/// 개인 커리큘럼은 마이페이지에서 열며, 관리 모드를 벗어나면 출석으로 돌아간다.
///
/// - Note: 표시 문자열은 ``title`` 로 노출한다. 레거시는 한글 문자열을 `rawValue` 로 썼지만,
///   `rawValue` 는 식별자(저장·비교)의 자리이지 화면 문구의 자리가 아니라 분리했다.
enum ActivitySection: String, Identifiable, Hashable, CaseIterable {

    // MARK: - Challenger

    case attendanceCheck
    case members

    // MARK: - Admin

    case attendanceManage
    case studyManage
    case memberManage

    // MARK: - Property

    var id: Self { self }

    /// 네비게이션 타이틀·섹션 메뉴에 표시할 문구
    var title: String {
        switch self {
        case .attendanceCheck: "출석 체크"
        case .members: "구성원"
        case .attendanceManage: "출석 관리"
        case .studyManage: "스터디 관리"
        case .memberManage: "멤버 관리"
        }
    }

    /// 섹션 메뉴 항목의 SF Symbol 이름
    var icon: String {
        switch self {
        case .attendanceCheck, .attendanceManage: "checkmark.circle"
        case .studyManage: "book.pages"
        case .members, .memberManage: "person.3"
        }
    }

    // MARK: - Function

    /// 모드별 사용 가능한 섹션 목록 (메뉴 노출 순서)
    static func sections(for mode: ActivityMode) -> [ActivitySection] {
        switch mode {
        case .challenger: [.attendanceCheck, .members]
        case .admin: [.attendanceManage, .studyManage, .memberManage]
        }
    }

    /// 모드별 기본 선택 섹션 (탭 진입 시 첫 화면)
    static func defaultSection(for mode: ActivityMode) -> ActivitySection {
        switch mode {
        case .challenger: .attendanceCheck
        case .admin: .attendanceManage
        }
    }

    /// 다른 모드에서 의미상 대응되는 섹션
    ///
    /// 모드 토글 직후에도 같은 성격의 화면(출석↔출석 관리 등)에 머물게 한다.
    /// 이미 그 모드에 속한 섹션이면 자기 자신을 돌려준다.
    func mapped(to mode: ActivityMode) -> ActivitySection {
        switch mode {
        case .challenger:
            switch self {
            case .attendanceCheck, .attendanceManage: .attendanceCheck
            case .studyManage: .attendanceCheck
            case .members, .memberManage: .members
            }
        case .admin:
            switch self {
            case .attendanceCheck, .attendanceManage: .attendanceManage
            case .studyManage: .studyManage
            case .members, .memberManage: .memberManage
            }
        }
    }
}
