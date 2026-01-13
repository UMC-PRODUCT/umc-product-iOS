//
//  MemberManagementCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import SwiftUI

// MARK: - MemberManagementCard

struct MemberManagementCard: View {
    
    // MARK: - Property

    let memberManagementItem: MemberManagementItem
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 15) {
            MemberImagePresenter(memberManagementItem: memberManagementItem)
            MemberTextPresenter(
                name: memberManagementItem.name,
                generation: memberManagementItem.generation,
                position: memberManagementItem.position,
                part: memberManagementItem.part
                )
            Spacer()
            MemberPenaltyPresenter(penalty: memberManagementItem.penalty)
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: 4, height: 8)
                .foregroundStyle(Color.grey400)
        }
        .padding(16)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.grey200, lineWidth: 1)
        )
    }
}

// MARK: - MemberImagePresenter
/// 프로필 사진, 뱃지
struct MemberImagePresenter: View {
    
    let memberManagementItem: MemberManagementItem
    
    var body: some View {
        Image(memberManagementItem.profile)
            .resizable()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .aspectRatio(contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                if memberManagementItem.badge {
                    MemberBadgePresenter()
                }
            }
    }
}

// MARK: - MemberTextPresenter
/// 멤버 정보
struct MemberTextPresenter: View {
    
    let name: String
    let generation: String
    let position: String
    let part: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(name)
                    .font(.app(.footnote, weight: .bold))
                
                Rectangle()
                    .frame(width: 1, height: 16)
                    .foregroundStyle(Color.grey300)
                
                Text(generation)
                    .font(.app(.caption1, weight: .regular))
                    .foregroundStyle(Color.grey900)
            }
            HStack {
                Text(position)
                    .font(.app(.caption1, weight: .regular))
                    .foregroundStyle(Color.grey500)
                
                Text(part)
                    .font(.app(.caption1, weight: .regular))
                    .foregroundStyle(Color.grey500)
            }
        }
    }
}

// MARK: - MemberPenaltyPresenter
/// 아웃 상태
/// - 0일 때: Clean ✨
/// - 0이 아닐 때: 경고 + 점수
struct MemberPenaltyPresenter: View {
    
    let penalty: Double
    
    var body: some View {
        if penalty != 0 {
            HStack(spacing: 3) {
                Text("경고")
                Text(String(format: "%.1f", penalty))
            }
            .font(.app(.caption1, weight: .bold))
            .foregroundStyle(Color.red700)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background (
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red100)
                    .strokeBorder(Color.red300, lineWidth: 0.5)
            )
        }
        else {
            Text("Clean ✨")
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.grey700)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background (
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.grey000, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - MemberImagePresenter
/// 선물 상자 뱃지
/// Bool 타입
/// - true: 나타남
/// - false: 사라짐
struct MemberBadgePresenter: View {
    var body: some View {
        Image(systemName: "gift")
            .resizable()
            .frame(width: 8, height: 8)
            .padding(3)
            .background {
                Circle()
                    .fill(Color.yellow300)
                    .stroke(Color.white, lineWidth: 2)
            }
    }
}


// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "8기", position: "Challenger", part: "iOS", penalty: 0, badge: true, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "8기", position: "Challenger", part: "iOS", penalty: 0, badge: false, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Challenger", part: "Spring Boot", penalty: 1.0, badge: true, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .profile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 1.0, badge: false, managementTeam: .partLeader))
        
    }
}

