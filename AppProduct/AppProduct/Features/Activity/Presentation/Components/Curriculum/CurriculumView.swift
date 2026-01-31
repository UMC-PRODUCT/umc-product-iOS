//
//  CurriculumView.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import SwiftUI

// MARK: - CurriculumView

/// 커리큘럼 상세 뷰 (진행률 카드 + 미션 리스트)
struct CurriculumView: View {

    // MARK: - Property

    let curriculumModel: CurriculumProgressModel
    let missions: [MissionCardModel]
    @FocusState private var focusedMissionID: UUID?
    var onMissionSubmit: (MissionCardModel, MissionSubmissionType, String?) -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing24) {
                // Header
                CurriculumProgressCard(model: curriculumModel)
                    .equatable()

                // Mission List
                missionListSection
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .contentMargins(
            .bottom,
            DefaultConstant.defaultContentBottomMargins,
            for: .scrollContent
        )
        .background(.white)
        .keyboardDismissToolbar(focusedID: $focusedMissionID)
    }

    // MARK: - View Components

    private var missionListSection: some View {
        ForEach(missions, id: \.id) { mission in
            HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
                // Left: Status Icon with Connector
                MissionStatusIcon(
                    status: mission.status,
                    weekNumber: mission.week
                )
                .equatable()

                // Right: MissionCard
                MissionCard(
                    model: mission,
                    focusedMissionID: $focusedMissionID
                ) { submissionType, link in
                    onMissionSubmit(mission, submissionType, link)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("CurriculumView - iOS") {
    struct PreviewWrapper: View {
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
    return PreviewWrapper()
}

#Preview("CurriculumView - Web") {
    struct PreviewWrapper: View {
        var body: some View {
            CurriculumView(
                curriculumModel: CurriculumProgressModel(
                    partName: "WEB PART CURRICULUM",
                    curriculumTitle: "웹 프론트엔드 기초",
                    completedCount: 5,
                    totalCount: 10
                ),
                missions: MissionPreviewData.webMissions
            ) { mission, type, link in
                print("제출: \(mission.title) - \(type) - \(link ?? "없음")")
            }
        }
    }
    return PreviewWrapper()
}

#Preview("CurriculumView - All Status") {
    struct PreviewWrapper: View {
        var body: some View {
            CurriculumView(
                curriculumModel: CurriculumProgressModel(
                    partName: "SERVER PART CURRICULUM",
                    curriculumTitle: "SpringBoot 실습",
                    completedCount: 3,
                    totalCount: 6
                ),
                missions: MissionPreviewData.allStatusMissions
            ) { mission, type, link in
                print("제출: \(mission.title) - \(type) - \(link ?? "없음")")
            }
        }
    }
    return PreviewWrapper()
}
#endif
