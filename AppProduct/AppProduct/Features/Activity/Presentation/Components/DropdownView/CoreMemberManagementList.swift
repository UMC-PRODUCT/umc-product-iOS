//
//  CoreMemberManagementList.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

struct CoreMemberManagementList: View {
    
    let memberManagementItem: MemberManagementItem
    
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

struct CoreMemberTextPresenter: View {
    
    let name: String
    let part: String
    
    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.app(.callout, weight: .bold))
            Text(part)
                .font(.app(.subheadline, weight: .regular))
                .foregroundStyle(Color.neutral500)
        }
    }
}

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

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 4) {
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .president))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .vicePresident))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .partLeader))
        
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 0, badge: false, managementTeam: .challenger))
    }
}
