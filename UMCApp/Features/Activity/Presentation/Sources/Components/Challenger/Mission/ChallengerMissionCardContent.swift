//
//  ChallengerMissionCardContent.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import ActivityDomain
import CoreDesignSystem

struct ChallengerMissionCardContent: View, Equatable {

    // MARK: - Property

    let model: MissionCardModel

    // MARK: - Body

    var body: some View {
        Text(model.missionTitle)
            .appFont(.subheadline, color: .grey600)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    ChallengerMissionCardContent(model: MissionPreviewData.singleMission)
        .padding()
}
#endif
