//
//  MemberManagementView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Admin 모드의 멤버 관리 섹션
///
/// 운영진이 동아리 멤버를 관리하는 화면입니다.
struct MemberManagementView: View {
    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("멤버 관리", systemImage: "person.crop.circle.badge.checkmark")
            } description: {
                Text("멤버 역할 변경, 경고 부여 등 멤버를 관리합니다")
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
    }
}

#Preview {
    MemberManagementView()
}
