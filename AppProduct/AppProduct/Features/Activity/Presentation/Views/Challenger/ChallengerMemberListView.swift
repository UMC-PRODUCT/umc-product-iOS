//
//  ChallengerMemberListView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Challenger 모드의 구성원 섹션
///
/// 동아리 구성원 목록을 표시합니다.
struct ChallengerMemberListView: View {
    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("구성원", systemImage: "person.3")
            } description: {
                Text("동아리 구성원 목록이 여기에 표시됩니다")
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
    }
}

#Preview {
    ChallengerMemberListView()
}
