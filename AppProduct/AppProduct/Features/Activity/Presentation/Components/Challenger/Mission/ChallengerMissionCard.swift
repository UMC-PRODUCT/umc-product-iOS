//
//  ChallengerMissionCard.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - ChallengerMissionCard (Container)

/// 미션 카드 메인 컴포넌트 (헤더 + 확장 콘텐츠)
struct ChallengerMissionCard: View {

    // MARK: - Property

    private let model: MissionCardModel
    private var focusedMissionID: FocusState<UUID?>.Binding
    private var onSubmit: (MissionSubmissionType, String?) -> Void

    @State private var isExpanded: Bool = false
    @State private var submissionType: MissionSubmissionType = .link
    @State private var linkText: String = ""

    // MARK: - Initializer

    init(
        model: MissionCardModel,
        focusedMissionID: FocusState<UUID?>.Binding,
        onSubmit: @escaping (MissionSubmissionType, String?) -> Void
    ) {
        self.model = model
        self.focusedMissionID = focusedMissionID
        self.onSubmit = onSubmit
        self._submissionType = State(initialValue: model.missionType.defaultSubmissionType)
    }

    // MARK: - Body

    var body: some View {
        ChallengerMissionCardPresenter(
            model: model,
            isExpanded: isExpanded,
            submissionType: submissionType,
            linkText: linkText,
            focusedMissionID: focusedMissionID,
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

// MARK: - ChallengerMissionCardPresenter

fileprivate struct ChallengerMissionCardPresenter: View, Equatable {

    // MARK: - Property

    let model: MissionCardModel
    let isExpanded: Bool
    let submissionType: MissionSubmissionType
    let linkText: String
    var focusedMissionID: FocusState<UUID?>.Binding
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
            ChallengerMissionCardHeader(
                model: model,
                isExpanded: isExpanded,
                onToggle: onToggleExpanded
            )

            if isExpanded {
                ChallengerMissionCardContent(
                    model: model,
                    submissionType: submissionType,
                    linkText: linkText,
                    focusedMissionID: focusedMissionID,
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
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(Color.white)
                .glass()
        }
        .animation(
            .easeInOut(duration: DefaultConstant.animationTime),
            value: isExpanded)
    }
}

// MARK: - Preview

#Preview("ChallengerMissionCard - All Status") {
    struct PreviewWrapper: View {
        @FocusState private var focusedMissionID: UUID?

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(MissionPreviewData.allStatusMissions) { mission in
                        ChallengerMissionCard(
                            model: mission,
                            focusedMissionID: $focusedMissionID
                        ) { type, link in
                            print("제출: \(type) - \(link ?? "없음")")
                        }
                    }
                }
                .padding()
            }
            .background(Color.grey100)
        }
    }
    return PreviewWrapper()
}

#Preview("ChallengerMissionCard - iOS Missions") {
    struct PreviewWrapper: View {
        @FocusState private var focusedMissionID: UUID?

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(MissionPreviewData.iosMissions) { mission in
                        ChallengerMissionCard(
                            model: mission,
                            focusedMissionID: $focusedMissionID
                        ) { type, link in
                            print("제출: \(type) - \(link ?? "없음")")
                        }
                    }
                }
                .padding()
            }
            .background(Color.grey100)
        }
    }
    return PreviewWrapper()
}

#Preview("ChallengerMissionCard - Single") {
    struct PreviewWrapper: View {
        @FocusState private var focusedMissionID: UUID?

        var body: some View {
            ChallengerMissionCard(
                model: MissionPreviewData.singleMission,
                focusedMissionID: $focusedMissionID
            ) { type, link in
                print("제출: \(type) - \(link ?? "없음")")
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
