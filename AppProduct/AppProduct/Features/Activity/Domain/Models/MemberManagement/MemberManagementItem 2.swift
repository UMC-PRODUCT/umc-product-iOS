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

enum ManagementTeam: String {
    case president = "👑 회장"
    case vicePresident = "⭐️ 부회장"
    case partLeader = "🚩 파트장"
    case challenger = "챌린저"
    
    var textColor: Color {
        switch self {
        case .president: return .red100
        case .vicePresident: return .indigo100
        case .partLeader: return .green500
        case .challenger: return .clear
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .president: return .red300
        case .vicePresident: return .indigo400
        case .partLeader: return .green100
        case .challenger: return .clear
        }
    }
    
    var borderColor: Color {
        switch self {
        case .president: return .red500
        case .vicePresident: return .indigo700
        case .partLeader: return .green300
        case .challenger: return .clear
        }
    }
}
