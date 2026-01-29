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
                .transition(.opacity.combined(with: .move(edge: .top)))
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

#Preview("MissionCard - All States") {
    ScrollView {
        VStack(spacing: 20) {
            MissionCard(
                model: MissionCardModel(
                    week: 1,
                    platform: "iOS",
                    title: "SwiftUI 기초 학습",
                    missionTitle: "SwiftUI를 이용해 로그인 화면을 구현하세요",
                    status: .notStarted
                )
            ) { type, link in
                print("제출: \(type) - \(link ?? "없음")")
            }

            MissionCard(
                model: MissionCardModel(
                    week: 2,
                    platform: "Android",
                    title: "Kotlin 기초 학습",
                    missionTitle: "Kotlin을 사용해 회원가입 화면을 만드세요",
                    status: .inProgress
                )
            ) { type, link in
                print("제출: \(type) - \(link ?? "없음")")
            }

            MissionCard(
                model: MissionCardModel(
                    week: 3,
                    platform: "Web",
                    title: "React 기초 학습",
                    missionTitle: "React로 메인 대시보드를 구현하세요",
                    status: .pass
                )
            ) { type, link in
                print("제출: \(type) - \(link ?? "없음")")
            }
        }
        .padding()
    }
}

#Preview("MissionCard - Expanded") {
    struct Demo: View {
        @State private var model = MissionCardModel(
            week: 1,
            platform: "iOS",
            title: "SwiftUI 기초 학습",
            missionTitle: "SwiftUI를 이용해 로그인 화면을 구현하세요",
            status: .inProgress
        )

        var body: some View {
            MissionCard(model: model) { type, link in
                print("제출: \(type) - \(link ?? "없음")")
            }
            .padding()
        }
    }

    return Demo()
}
