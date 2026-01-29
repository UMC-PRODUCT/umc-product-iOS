//
//  MemberManagementCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import SwiftUI

// MARK: - MemberManagementCard
struct MemberManagementCard: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let hstackSpacing: CGFloat = 15
        static let chevronSize: CGSize = .init(width: 4, height: 8)
        static let innerPadding: CGFloat = 16
        static let radius: CGFloat = 14
        static let strokeWidth: CGFloat = 1
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: Constants.hstackSpacing) {
            MemberImagePresenter(memberManagementItem: memberManagementItem)
            MemberTextPresenter(memberManagementItem: memberManagementItem)
            Spacer()
            MemberPenaltyPresenter(memberManagementItem: memberManagementItem)
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: Constants.chevronSize.width, height: Constants.chevronSize.height)
                .foregroundStyle(Color.grey400)
        }
        .padding(Constants.innerPadding)
        .background {
            RoundedRectangle(cornerRadius: Constants.radius)
                .strokeBorder(Color.grey200, lineWidth: Constants.strokeWidth)
        }
    }
}


// MARK: - MemberImagePresenter
/// 프로필 사진, 뱃지
/// CoreMemberManagementCard에서도 쓰이는 struct
struct MemberImagePresenter: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let imageSize: CGSize = .init(width: 40, height: 40)
    }
    
    // MARK: - Body
    var body: some View {
        Image(memberManagementItem.profile)
            .resizable()
            .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
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
private struct MemberTextPresenter: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let vstackSpacing: CGFloat = 2
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.vstackSpacing) {
            MemberTopTextPresenter(memberManagementItem: memberManagementItem)
            
            MemberBottomTextPresenter(memberManagementItem: memberManagementItem)
        }
    }
}


// MARK: - MemberTopTextPresenter
/// 이름, 기수
private struct MemberTopTextPresenter: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let rectangleSize: CGSize = .init(width: 1, height: 16)
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(memberManagementItem.name)
                .font(.app(.footnote, weight: .bold))
            
            Rectangle()
                .frame(width: Constants.rectangleSize.width, height: Constants.rectangleSize.height)
                .foregroundStyle(Color.grey300)
            
            Text(memberManagementItem.generation)
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.grey900)
        }
    }
}


// MARK: - MemberBottomTextPresenter
/// 챌린저/운영진, 파트
private struct MemberBottomTextPresenter: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Body
    var body: some View {
        HStack {
            Text(memberManagementItem.position)
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.grey500)
            
            Text(memberManagementItem.part)
                .font(.app(.caption1, weight: .regular))
                .foregroundStyle(Color.grey500)
        }
    }
}


// MARK: - MemberPenaltyPresenter
/// 아웃 상태
/// - 0일 때: 아무것도 나타나지않음
/// - 0이 아닐 때: 경고 + 점수
private struct MemberPenaltyPresenter: View, Equatable {
    
    // MARK: - Property
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let hstackSpacing: CGFloat = 3
        static let horizonSpacing: CGFloat = 8
        static let verticalSpacing: CGFloat = 4
        static let radius: CGFloat = 8
        static let strokeWidth: CGFloat = 0.5
    }
    
    // MARK: - Body
    var body: some View {
        if memberManagementItem.penalty != 0 {
            HStack(spacing: Constants.hstackSpacing) {
                Text("경고")
                Text(String(format: "%.1f", memberManagementItem.penalty))
            }
            .font(.app(.caption1, weight: .bold))
            .foregroundStyle(Color.red700)
            .padding(.horizontal, Constants.horizonSpacing)
            .padding(.vertical, Constants.verticalSpacing)
            .background {
                RoundedRectangle(cornerRadius: Constants.radius)
                    .fill(Color.red100)
                    .strokeBorder(Color.red300, lineWidth: Constants.strokeWidth)
            }
        }
        else {
            EmptyView()
        }
    }
}


// MARK: - MemberImagePresenter
/// 선물 상자 뱃지
/// Bool 타입
/// - true: 나타남
/// - false: 사라짐
private struct MemberBadgePresenter: View, Equatable {
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let imageSize: CGSize = .init(width: 8, height: 8)
        static let innerPadding: CGFloat = 3
        static let strokeWidth: CGFloat = 2
    }
    
    // MARK: - Body
    var body: some View {
        Image(systemName: "gift")
            .resizable()
            .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
            .padding(Constants.innerPadding)
            .background {
                Circle()
                    .fill(Color.yellow300)
                    .stroke(Color.white, lineWidth: Constants.strokeWidth)
            }
    }
}


// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .defaultProfile, name: "이예지", generation: "8기", position: "Challenger", part: "iOS", penalty: 0, badge: true, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .defaultProfile, name: "이예지", generation: "8기", position: "Challenger", part: "iOS", penalty: 0, badge: false, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .defaultProfile, name: "이예지", generation: "9기", position: "Challenger", part: "Spring Boot", penalty: 1.0, badge: true, managementTeam: .challenger))
        
        MemberManagementCard(memberManagementItem: MemberManagementItem(profile: .defaultProfile, name: "이예지", generation: "9기", position: "Part Leader", part: "iOS", penalty: 1.0, badge: false, managementTeam: .campusPartLeader))
        
    }
}

