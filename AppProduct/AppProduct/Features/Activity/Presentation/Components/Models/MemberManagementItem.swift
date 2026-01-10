//
//  MemberManagementItem.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import Foundation
import SwiftUI

struct MemberManagementItem: Identifiable {
    let id: UUID = .init()
    let profile: ImageResource
    let name: String
    let generation: String
    let position: String
    let part: String
    let penalty: Double
    let badge: Bool
    let managementTeam: ManagementTeam
}

enum ManagementTeam: String {
    case president = "👑 회장"
    case vicePresident = "⭐️ 부회장"
    case partLeader = "🚩 파트장"
    case challenger = "챌린저"
    
    var textColor: Color {
        switch self {
        case .president: return .accent700
        case .vicePresident: return .primary600
        case .partLeader: return .success500
        case .challenger: return .clear
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .president: return .accent100
        case .vicePresident: return .primary100
        case .partLeader: return .success100
        case .challenger: return .clear
        }
    }
    
    var borderColor: Color {
        switch self {
        case .president: return .accent300
        case .vicePresident: return .primary300
        case .partLeader: return .success300
        case .challenger: return .clear
        }
    }
}
