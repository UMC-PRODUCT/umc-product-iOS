//
//  ChallengerStudyView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Challenger 모드의 스터디/활동 섹션
///
/// 참여 중인 스터디와 활동 목록을 표시합니다.
struct ChallengerStudyView: View {
    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("스터디/활동", systemImage: "book.pages")
            } description: {
                Text("참여 중인 스터디와 활동 목록이 여기에 표시됩니다")
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultSafeBottom)
        }
    }
}

#Preview {
    ChallengerStudyView()
}
