//
//  CoreManagement.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import Foundation
import SwiftUI

// MARK: - CoreManagement
/// Dropdown되었을 때 보이는 스터디 관리/멤버 관리 리스트
enum CoreManagement {
    case study(studyManagementItem: StudyManagementItem)
    case member(memberManagementItem: MemberManagementItem)
    
    var listView: AnyView {
        switch self {
        case .study(let studyManagementItem):
            return AnyView(CoreStudyManagementList(studyManagementItem: studyManagementItem))
        case .member(let memberManagementItem):
            return AnyView(CoreMemberManagementList(memberManagementItem: memberManagementItem))
        }
    }
}

