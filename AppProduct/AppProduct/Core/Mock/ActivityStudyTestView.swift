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
            VStack(spacing: 20) {
                ForEach(MissionPreviewData.allStatusMissions) { mission in
                    MissionCard(
                        model: mission,
                        focusedMissionID: $focusedMissionID
                    ) { type, link in
                        print("제출: \(type) - \(link ?? "없음")")
                    }
                }
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .keyboardDismissToolbar(focusedID: $focusedMissionID)
    }
}

#Preview {
    ActivityStudyTestView()
}
