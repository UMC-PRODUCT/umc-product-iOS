//
//  ChallengerMissionCardContent.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 7/15/26.
//

import SwiftUI
import CoreDesignSystem

struct ChallengerMissionCardContent: View, Equatable {

    // MARK: - Property

    let description: String

    // MARK: - Body

    var body: some View {
        Text(description)
            .appFont(.subheadline, color: .grey700)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    ChallengerMissionCardContent(
        description: MissionPreviewData.singleMission.missionTitle
    )
    .padding()
}
#endif
