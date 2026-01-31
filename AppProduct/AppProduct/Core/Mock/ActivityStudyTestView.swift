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

    // MARK: - Constants

    private enum Constants {
        static let iconSize: CGFloat = 28
        static let connectorWidth: CGFloat = 2
    }

    private var curriculumViewSection: some View {
        let missions = MissionPreviewData.webCurriculumMissions

        return VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text("커리큘럼 상세 (CurriculumView)")
                .appFont(.title3Emphasis)

            // CurriculumView: CurriculumProgressCard + MissionCard 리스트 조합
            VStack(spacing: 0) {
                // Header
                CurriculumProgressCard(
                    model: CurriculumProgressModel(
                        partName: "WEB PART CURRICULUM",
                        curriculumTitle: "웹 프론트엔드 기초",
                        completedCount: 2,
                        totalCount: 8
                    )
                )
                .equatable()
                .padding(.bottom, DefaultSpacing.spacing24)

                // Mission List with Connector
                VStack(spacing: 0) {
                    ForEach(Array(missions.enumerated()), id: \.element.id) { index, mission in
                        let isLast = index == missions.count - 1

                        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
                            // Left: Icon + Connector
                            ZStack(alignment: .top) {
                                // 연결선 (아이콘 아래부터)
                                if !isLast {
                                    Rectangle()
                                        .fill(Color.grey300)
                                        .frame(width: Constants.connectorWidth)
                                        .padding(.top, Constants.iconSize)
                                }

                                // 아이콘
                                MissionStatusIcon(
                                    status: mission.status,
                                    weekNumber: mission.week
                                )
                                .equatable()
                            }
                            .frame(width: Constants.iconSize)
                            .frame(maxHeight: .infinity, alignment: .top)

                            MissionCard(
                                model: mission,
                                focusedMissionID: $focusedMissionID
                            ) { type, link in
                                print("제출: \(type) - \(link ?? "없음")")
                            }
                            .padding(.bottom, isLast ? 0 : DefaultSpacing.spacing12)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityStudyTestView()
}
#endif
