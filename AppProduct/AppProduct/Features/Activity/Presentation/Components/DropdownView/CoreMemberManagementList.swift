//
//  CoreMemberManagementList.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - CoreMemberManagementList
struct CoreMemberManagementList: View {
    
    // MARK: - Property
    
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            MemberImagePresenter(memberManagementItem: memberManagementItem)
            CoreMemberTextPresenter(
                name: memberManagementItem.name,
                part: memberManagementItem.part
            )
            Spacer()
            ManagementTeamBadgePresenter(managementTeam: memberManagementItem.managementTeam)
        }
    }
}

// MARK: - CoreMemberTextPresenter
/// 이름, 파트
struct CoreMemberTextPresenter: View {
    
    let name: String
    let part: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.app(.callout, weight: .bold))
            Text(part)
                .font(.app(.subheadline, weight: .regular))
                .foregroundStyle(Color.grey500)
        }
    }
}

// MARK: - ManagementTeamBadgePresenter
/// 운영진 뱃지
/// - 회장, 부회장, 파트장
/// - 챌린저일 때 나타나지않음
struct ManagementTeamBadgePresenter: View {
    
    let managementTeam: ManagementTeam
    
    var body: some View {
        Text(managementTeam.rawValue)
            .font(.app(.caption2, weight: .regular))
            .foregroundStyle(managementTeam.textColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(managementTeam.backgroundColor)
                    .strokeBorder(managementTeam.borderColor)
            }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 4) {
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .president))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .vicePresident))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .partLeader))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .challenger))
    }
}
