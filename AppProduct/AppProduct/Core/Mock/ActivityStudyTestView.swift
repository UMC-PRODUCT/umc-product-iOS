//
//  ActivityStudyTestView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/30/26.
//

import SwiftUI

#if DEBUG
struct ActivityStudyTestView: View {
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
    ActivityStudyTestView()
}
#endif
