//
//  MissionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCard

/// 미션 카드 메인 컴포넌트 (헤더 + 확장 콘텐츠)
struct MissionCard: View {

    // MARK: - Property

    let model: MissionCardModel
    var onSubmit: (MissionSubmissionType, String?) -> Void

    @State private var isExpanded: Bool = false
    @State private var submissionType: MissionSubmissionType = .link
    @State private var linkText: String = ""

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            MissionCardHeader(
                model: model,
                isExpanded: isExpanded
            ) {
                withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                Divider()

                MissionCardContent(
                    missionTitle: model.missionTitle,
                    submissionType: $submissionType,
                    linkText: $linkText,
                    onSubmit: onSubmit
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: DefaultConstant.transitionScale).combined(with: .opacity),
                    removal: .scale(scale: DefaultConstant.transitionScale).combined(with: .opacity)))
            }
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(Color.grey000)
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .containerShape(.rect(cornerRadius: DefaultConstant.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .animation(.easeInOut(duration: DefaultConstant.animationTime), value: isExpanded)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("MissionCard - All Status") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(MissionPreviewData.allStatusMissions) { mission in
                MissionCard(model: mission) { type, link in
                    print("제출: \(type) - \(link ?? "없음")")
                }
            }
        }
        .padding()
    }
    .background(Color.grey100)
}

#Preview("MissionCard - iOS Missions") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(MissionPreviewData.iosMissions) { mission in
                MissionCard(model: mission) { type, link in
                    print("제출: \(type) - \(link ?? "없음")")
                }
            }
        }
        .padding()
    }
    .background(Color.grey100)
}

#Preview("MissionCard - Single") {
    MissionCard(model: MissionPreviewData.singleMission) { type, link in
        print("제출: \(type) - \(link ?? "없음")")
    }
    .padding()
}
#endif
