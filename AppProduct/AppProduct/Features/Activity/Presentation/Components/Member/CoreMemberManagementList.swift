//
//  CoreMemberManagementList.swift
//  AppProduct
//
//  Created by 이예지 on 1/10/26.
//

import SwiftUI

// MARK: - CoreMemberManagementList

/// 핵심 운영진 멤버 리스트 아이템 뷰입니다.
///
/// 프로필 이미지, 이름, 파트, 그리고 운영진 뱃지를 가로로 배치하여 보여줍니다.
struct CoreMemberManagementList: View {
    
    // MARK: - Property
    
    /// 표시할 멤버 정보
    let memberManagementItem: MemberManagementItem
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // 멤버 프로필 이미지
            MemberImagePresenter(memberManagementItem: memberManagementItem)
            
            // 멤버 텍스트 정보 (이름, 파트)
            CoreMemberTextPresenter(
                name: memberManagementItem.name,
                nickname: memberManagementItem.nickname,
                part: memberManagementItem.generation
            )
            
            Spacer()
            
            // 운영진 뱃지 (회장, 부회장 등)
            ManagementTeamBadgePresenter(managementTeam: memberManagementItem.managementTeam)
        }
    }
}

// MARK: - CoreMemberTextPresenter

/// 멤버의 이름과 파트 정보를 표시하는 텍스트 뷰 조합입니다.
struct CoreMemberTextPresenter: View {
    
    /// 멤버 이름
    let name: String
    
    /// 멤버 닉네임
    let nickname: String
    
    /// 소속 파트
    let part: String
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text("\(name)/\(nickname)")
                .appFont(.calloutEmphasis, color: .black)
            
            Text(part)
                .appFont(.subheadline, color: .grey500)
        }
    }
}

// MARK: - ManagementTeamBadgePresenter

/// 운영진 직책을 나타내는 뱃지 뷰입니다.
///
/// - 회장, 부회장, 파트장 등 직책에 따라 다른 색상과 텍스트를 표시합니다.
/// - 일반 챌린저(.challenger)인 경우 텍스트를 표시하지 않을 수 있습니다 (ManagementTeam 구현에 따라 다름).
struct ManagementTeamBadgePresenter: View {
    
    /// 운영진 직책 타입
    let managementTeam: ManagementTeam
    
    private enum Constants {
        static let verticalPadding: CGFloat = 6
        static let horizontalPadding: CGFloat = 8
    }
    
    var body: some View {
        Text(managementTeam.korean)
            .font(.app(.footnote, weight: .regular))
            .foregroundStyle(managementTeam.textColor)
            .padding(.vertical, Constants.verticalPadding)
            .padding(.horizontal, Constants.horizontalPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                    .fill(managementTeam.backgroundColor)
            }
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 4) {
        CoreMemberManagementList(memberManagementItem: MemberManagementItem(profile: nil, name: "이예지", nickname: "소피", generation: "9기", position: "Part Leader", part: .front(type: .ios), penalty: 0, badge: false, managementTeam: .schoolPartLeader, attendanceRecords: []))
    }
}
