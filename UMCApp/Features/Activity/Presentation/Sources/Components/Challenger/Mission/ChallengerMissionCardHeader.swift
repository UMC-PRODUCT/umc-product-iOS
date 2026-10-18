//
//  ChallengerMissionCardHeader.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

struct ChallengerMissionCardHeader: View, Equatable {

    // MARK: - Property

    let model: MissionCardModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text("\(model.week)주차")
                .appFont(.footnote, weight: .semibold, color: .grey700)

            Text(model.title)
                .appFont(.body, weight: .semibold, color: .grey900)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview {
    ChallengerMissionCardHeader(model: MissionPreviewData.singleMission)
        .padding(DefaultConstant.defaultListPadding)
}
#endif
