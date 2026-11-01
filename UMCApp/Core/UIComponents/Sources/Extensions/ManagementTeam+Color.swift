//
//  ManagementTeam+Color.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

extension ManagementTeam {
    /// 태그 전용 표기. 권한과 상세 직책 이름은 원본 도메인에 보존한다.
    public var tagName: String {
        switch self {
        case .superAdmin: "Admin"
        case .centralOperatingTeamMember, .centralEducationTeamMember: "중앙 운영진"
        case .schoolPartLeader, .schoolEtcAdmin: "교내 운영진"
        default: korean
        }
    }

    public var textColor: Color {
        switch self {
        case .superAdmin, .challenger: .tagRoleAdminText
        case .centralPresident, .centralVicePresident,
             .centralOperatingTeamMember, .centralEducationTeamMember: .tagRoleCentralText
        case .chapterPresident: .tagRoleChapterText
        case .schoolPresident, .schoolVicePresident,
             .schoolPartLeader, .schoolEtcAdmin: .tagRoleCampusText
        }
    }

    public var backgroundColor: Color {
        switch self {
        case .superAdmin, .challenger: .tagRoleAdminBackground
        case .centralPresident, .centralVicePresident,
             .centralOperatingTeamMember, .centralEducationTeamMember: .tagRoleCentralBackground
        case .chapterPresident: .tagRoleChapterBackground
        case .schoolPresident, .schoolVicePresident,
             .schoolPartLeader, .schoolEtcAdmin: .tagRoleCampusBackground
        }
    }

    public var borderColor: Color { backgroundColor }
}
