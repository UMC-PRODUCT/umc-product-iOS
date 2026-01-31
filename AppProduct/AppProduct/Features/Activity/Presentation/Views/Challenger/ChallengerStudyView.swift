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
        CurriculumView(
            curriculumModel: CurriculumProgressModel(
                partName: "iOS PART CURRICULUM",
                curriculumTitle: "Swift 기초 문법",
                completedCount: 2,
                totalCount: 8
            ),
            missions: MissionPreviewData.iosMissions
        ) { mission, type, link in
            print("제출: \(mission.title) - \(type) - \(link ?? "없음")")
        }
    }
}

#Preview {
    ChallengerStudyView()
}
