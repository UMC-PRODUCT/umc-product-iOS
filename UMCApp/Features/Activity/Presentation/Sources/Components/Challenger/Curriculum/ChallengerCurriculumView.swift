//
//  ChallengerCurriculumView.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

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

                ForEach(missions) { mission in
                    ChallengerMissionCard(model: mission)
                }
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .defaultScrollAnchor(.top)
        .contentMargins(
            .bottom,
            DefaultConstant.defaultContentBottomMargins,
            for: .scrollContent
        )
        .background(.white)
        .scrollDismissesKeyboard(.immediately)
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
