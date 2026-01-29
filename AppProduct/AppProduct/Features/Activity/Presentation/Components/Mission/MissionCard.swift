//
//  MissionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCard (Container)

/// 미션 카드 메인 컴포넌트 (헤더 + 확장 콘텐츠)
struct MissionCard: View {

    // MARK: - Property

    private let model: MissionCardModel
    private var onSubmit: (MissionSubmissionType, String?) -> Void

    @State private var isExpanded: Bool = false
    @State private var submissionType: MissionSubmissionType = .link
    @State private var linkText: String = ""

    // MARK: - Initializer

    init(
        model: MissionCardModel,
        onSubmit: @escaping (MissionSubmissionType, String?) -> Void
    ) {
        self.model = model
        self.onSubmit = onSubmit
    }

    // MARK: - Body

    var body: some View {
        MissionCardPresenter(
            model: model,
            isExpanded: isExpanded,
            submissionType: submissionType,
            linkText: linkText,
            onToggleExpanded: {
                withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                    isExpanded.toggle()
                }
            },
            onSubmissionTypeChanged: { newType in
                submissionType = newType
            },
            onLinkTextChanged: { newText in
                linkText = newText
            },
            onSubmit: onSubmit
        )
        .equatable()
    }
}

// MARK: - MissionCardPresenter

fileprivate struct MissionCardPresenter: View, Equatable {

    // MARK: - Property

    let model: MissionCardModel
    let isExpanded: Bool
    let submissionType: MissionSubmissionType
    let linkText: String
    let onToggleExpanded: () -> Void
    let onSubmissionTypeChanged: (MissionSubmissionType) -> Void
    let onLinkTextChanged: (String) -> Void
    let onSubmit: (MissionSubmissionType, String?) -> Void

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.model == rhs.model &&
        lhs.isExpanded == rhs.isExpanded &&
        lhs.submissionType == rhs.submissionType &&
        lhs.linkText == rhs.linkText
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            MissionCardHeader(
                model: model,
                isExpanded: isExpanded,
                onToggle: onToggleExpanded
            )

            if isExpanded {
                Divider()

                MissionCardContent(
                    missionTitle: model.missionTitle,
                    submissionType: submissionType,
                    linkText: linkText,
                    onSubmissionTypeChanged: onSubmissionTypeChanged,
                    onLinkTextChanged: onLinkTextChanged,
                    onSubmit: onSubmit
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: DefaultConstant.transitionScale).combined(with: .opacity),
                    removal: .scale(scale: DefaultConstant.transitionScale).combined(with: .opacity)))
            }
        }
        .padding(DefaultConstant.defaultListPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .containerShape(.rect(cornerRadius: DefaultConstant.cornerRadius))
        .animation(
            .easeInOut(duration: DefaultConstant.animationTime),
            value: isExpanded)
        .glass()
    }
}

// MARK: - Preview

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
