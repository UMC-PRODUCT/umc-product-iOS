//
//  ChallengerCurriculumView.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

fileprivate enum Constants {
    static let rowStackSpacing: CGFloat = 0
}

struct ChallengerCurriculumView: View {

    // MARK: - Property

    let curriculumModel: CurriculumHeaderModel
    let missions: [MissionCardModel]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DefaultSpacing.spacing24) {
                ChallengerCurriculumHeaderCard(model: curriculumModel)
                    .equatable()

                ChallengerCurriculumWeekList(missions: missions)
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .defaultScrollAnchor(.top)
        .contentMargins(
            .bottom,
            DefaultConstant.defaultContentBottomMargins,
            for: .scrollContent
        )
        .background(Color.grey100)
        .scrollDismissesKeyboard(.immediately)
    }
}

fileprivate struct ChallengerCurriculumWeekList: View {

    // MARK: - Property

    let missions: [MissionCardModel]

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.rowStackSpacing) {
            ForEach(missions) { mission in
                ChallengerMissionCard(
                    model: mission,
                    isFirst: mission.id == missions.first?.id,
                    isLast: mission.id == missions.last?.id
                )
                .equatable()
            }
        }
    }
}

#if DEBUG
#Preview {
    ChallengerCurriculumView(
        curriculumModel: MissionPreviewData.sampleHeader,
        missions: MissionPreviewData.iosMissions
    )
}
#endif
