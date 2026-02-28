//
//  StudyManagementItem.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import Foundation
import SwiftUI

// MARK: - StudyManagementItem
/// - StudyManagementCard
/// - CoreStudyManagementList
struct StudyManagementItem: Identifiable, Equatable {
    let id: UUID = .init()
    let profile: String?
    let name: String
    let school: String
    let part: String
    let title: String
    // CoreStudyManageItem
    let state: StudySubmitState
}

enum StudySubmitState: String {
    case examine = "검토"
}
