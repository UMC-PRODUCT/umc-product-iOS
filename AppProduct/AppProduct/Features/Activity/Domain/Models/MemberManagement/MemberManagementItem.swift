//
//  MemberManagementItem.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import Foundation
import SwiftUI

// MARK: - MemberManagementItem
/// - MemberManagementCard
/// - CoreMemberManagementList
struct MemberManagementItem: Identifiable, Equatable {
    let id: UUID = .init()
    let profile: ImageResource
    let name: String
    let generation: String
    let position: String
    let part: String
    let penalty: Double
    let badge: Bool
    // CoreManagementItem
    let managementTeam: ManagementTeam
}
