//
//  ActivityStudyTestView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/30/26.
//

import SwiftUI

struct ActivityStudyTestView: View {

    // MARK: - Property

    @FocusState private var focusedMissionID: UUID?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing24) {
                // MARK: - Curriculum Progress Section
                curriculumSection

                // MARK: - Mission Section
                missionSection
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .background(Color.grey100)
        .keyboardDismissToolbar(focusedID: $focusedMissionID)
    }

    // MARK: - View Components

    private var curriculumSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("커리큘럼 진행률")
                .appFont(.title3Emphasis)

            ForEach(CurriculumPreviewData.allProgressStates) { curriculum in
                CurriculumProgressCard(model: curriculum)
                    .equatable()
            }
        }
    }

    private var missionSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("미션 카드")
                .appFont(.title3Emphasis)

            ForEach(MissionPreviewData.allStatusMissions) { mission in
                MissionCard(
                    model: mission,
                    focusedMissionID: $focusedMissionID
                ) { type, link in
                    print("제출: \(type) - \(link ?? "없음")")
                }
            }
        }
    }
}

#Preview {
    ActivityStudyTestView()
}
