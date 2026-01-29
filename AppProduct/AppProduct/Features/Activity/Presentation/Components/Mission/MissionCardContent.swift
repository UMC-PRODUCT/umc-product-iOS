//
//  MissionCardContent.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCardContent

/// 미션 카드 확장 콘텐츠 (미션 설명, 제출 타입 선택, 링크 입력/제출 버튼)
struct MissionCardContent: View {

    // MARK: - Property

    let missionTitle: String
    @Binding var submissionType: MissionSubmissionType
    @Binding var linkText: String
    let onSubmit: (MissionSubmissionType, String?) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text(missionTitle)
                .appFont(.calloutEmphasis, color: .black)

            HStack(spacing: DefaultSpacing.spacing8) {
                ForEach(MissionSubmissionType.allCases, id: \.hashValue) { type in
                    ChipButton(
                        type.rawValue,
                        isSelected: submissionType == type,
                        leadingIcon: type.icon
                    ) {
                        submissionType = type
                    }
                    .buttonSize(.small)
                }
            }

            if submissionType == .link {
                LinkSubmissionView(
                    linkText: $linkText,
                    onSubmit: { onSubmit(.link, linkText) }
                )
            } else {
                CompleteOnlySubmissionView(
                    onSubmit: { onSubmit(.completeOnly, nil) }
                )
            }
        }
    }
}

// MARK: - LinkSubmissionView

/// 링크 제출 뷰 (텍스트 필드 + 제출 버튼)
fileprivate struct LinkSubmissionView: View, Equatable {

    // MARK: - Property

    @Binding var linkText: String
    let onSubmit: () -> Void

    static func == (lhs: LinkSubmissionView, rhs: LinkSubmissionView) -> Bool {
        lhs.linkText == rhs.linkText
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            TextField("https://...", text: $linkText)
                .appFont(.footnote, weight: .regular, color: .grey500)
                .padding(.horizontal, DefaultConstant.defaultTextFieldPadding)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                        .strokeBorder(Color.grey300, lineWidth: 1)
                )

            MainButton("제출") {
                onSubmit()
            }
            .buttonSize(.small)
            .frame(maxWidth: 80)
            .buttonStyle(.glassProminent)
        }
    }
}

// MARK: - CompleteOnlySubmissionView

/// 완료만 제출 뷰 (제출 버튼만)
private struct CompleteOnlySubmissionView: View, Equatable {

    // MARK: - Property

    let onSubmit: () -> Void

    static func == (lhs: CompleteOnlySubmissionView, rhs: CompleteOnlySubmissionView) -> Bool {
        true
    }

    // MARK: - Body

    var body: some View {
        MainButton("제출") {
            onSubmit()
        }
        .buttonSize(.small)
        .buttonStyle(.primary)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("MissionCardContent", traits: .sizeThatFitsLayout) {
    struct Demo: View {
        @State private var submissionType: MissionSubmissionType = .link
        @State private var linkText: String = ""

        var body: some View {
            ZStack {
                Color.grey100.ignoresSafeArea()

                MissionCardContent(
                    missionTitle: MissionPreviewData.singleMission.missionTitle,
                    submissionType: $submissionType,
                    linkText: $linkText
                ) { type, link in
                    print("제출: \(type) - \(link ?? "없음")")
                }
                .padding()
                .background(Color.grey000)
                .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            }
        }
    }

    return Demo()
}
#endif
