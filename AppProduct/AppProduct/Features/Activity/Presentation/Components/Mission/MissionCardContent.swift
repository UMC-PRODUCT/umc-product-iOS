//
//  MissionCardContent.swift
//  AppProduct
//
//  Created by jaewon Lee on 01/29/26.
//

import SwiftUI

// MARK: - MissionCardContent

/// 미션 카드 확장 콘텐츠 (미션 설명, 제출 타입 선택, 링크 입력/제출 버튼)
struct MissionCardContent: View, Equatable {

    // MARK: - Property

    let missionTitle: String
    let status: MissionStatus
    let submissionType: MissionSubmissionType
    let linkText: String
    let onSubmissionTypeChanged: (MissionSubmissionType) -> Void
    let onLinkTextChanged: (String) -> Void
    let onSubmit: (MissionSubmissionType, String?) -> Void

    static func == (lhs: MissionCardContent, rhs: MissionCardContent) -> Bool {
        lhs.missionTitle == rhs.missionTitle &&
        lhs.status == rhs.status &&
        lhs.submissionType == rhs.submissionType &&
        lhs.linkText == rhs.linkText
    }
    
    private enum Constants {
        static let statusPadding: EdgeInsets = .init(
            top: 14, leading: 12, bottom: 14, trailing: 12)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            Text(missionTitle)
                .appFont(.subheadline, color: .gray)

            switch status {
            case .notStarted, .inProgress:
                submissionView
            case .pendingApproval:
                pendingApprovalView
            case .pass:
                passView
            case .fail:
                failView
            }
        }
    }

    // MARK: - Private Views

    private var submissionView: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            HStack(spacing: DefaultSpacing.spacing8) {
                ForEach(MissionSubmissionType.allCases, id: \.hashValue) { type in
                    ChipButton(
                        type.rawValue,
                        isSelected: submissionType == type,
                        leadingIcon: type.icon
                    ) {
                        withAnimation(
                            .easeInOut(duration: DefaultConstant.animationTime)) {
                            onSubmissionTypeChanged(type)
                        }
                    }
                    .buttonSize(.small)
                }
            }

            if submissionType == .link {
                LinkSubmissionView(
                    linkText: linkText,
                    onLinkTextChanged: onLinkTextChanged,
                    onSubmit: { onSubmit(.link, linkText) }
                )
            } else {
                CompleteOnlySubmissionView(
                    onSubmit: { onSubmit(.completeOnly, nil) }
                )
            }
        }
    }

    private var pendingApprovalView: some View {
        HStack {
            Image(systemName: "hourglass")
                .foregroundStyle(Color.orange)
            Text("학습 완료 확인 대기 중입니다.")
                .appFont(.callout, color: .orange)
        }
        .padding(Constants.statusPadding)
        .frame(maxWidth: .infinity)
        .background(
            Color.orange.opacity(0.15),
            in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
        )
    }

    private var passView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
            Text("해당 주차 스터디를 통과하였습니다.")
                .appFont(.callout, color: .green)
        }
        .padding(Constants.statusPadding)
        .frame(maxWidth: .infinity)
        .background(
            Color.green.opacity(0.15),
            in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
        )
    }

    private var failView: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.red)
            Text("해당 주차 스터디를 통과하지 못했습니다.")
                .appFont(.callout, color: .red)
        }
        .padding(Constants.statusPadding)
        .frame(maxWidth: .infinity)
        .background(
            Color.red.opacity(0.15),
            in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
        )
    }
}

// MARK: - LinkSubmissionView

/// 링크 제출 뷰 (텍스트 필드 + 제출 버튼)
fileprivate struct LinkSubmissionView: View, Equatable {

    // MARK: - Property

    let linkText: String
    let onLinkTextChanged: (String) -> Void
    let onSubmit: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.linkText == rhs.linkText
    }
    
    // MARK: - Constants

    private enum Constants {
        static let textFieldHeight: CGFloat = 50
        static let submitButtonWidth: CGFloat = 80
        static let borderWidth: CGFloat = 1
        static let buttonPadding: CGFloat = 10
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            linkInput
            submitButton
        }
    }
    
    private var linkInput: some View {
        TextField("https://...", text: Binding(
            get: { linkText },
            set: { onLinkTextChanged($0) }
        ))
        .appFont(.footnote, weight: .regular, color: .grey500)
        .padding(DefaultConstant.defaultTextFieldPadding)
        .background(
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .strokeBorder(Color.grey300, lineWidth: Constants.borderWidth)
        )
    }
    
    private var submitButton: some View {
        Button {
            onSubmit()
        } label: {
            Text("제출")
                .appFont(.subheadline, weight: .bold, color: .white)
                .padding(Constants.buttonPadding)
        }
        .buttonStyle(.glassProminent)
        .tint(.indigo500)
    }
}

// MARK: - CompleteOnlySubmissionView

/// 완료만 제출 뷰 (제출 버튼만)
private struct CompleteOnlySubmissionView: View, Equatable {

    // MARK: - Property

    let onSubmit: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    // MARK: - Body

    var body: some View {
        MainButton("제출") {
            onSubmit()
        }
        .buttonStyle(.primary)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("MissionCardContent - InProgress", traits: .sizeThatFitsLayout) {
    struct Demo: View {
        @State private var submissionType: MissionSubmissionType = .link
        @State private var linkText: String = ""

        var body: some View {
            ZStack {
                Color.grey100.ignoresSafeArea()

                MissionCardContent(
                    missionTitle: MissionPreviewData.singleMission.missionTitle,
                    status: .inProgress,
                    submissionType: submissionType,
                    linkText: linkText,
                    onSubmissionTypeChanged: { submissionType = $0 },
                    onLinkTextChanged: { linkText = $0 },
                    onSubmit: { type, link in
                        print("제출: \(type) - \(link ?? "없음")")
                    }
                )
                .padding()
                .background(Color.grey000)
                .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
            }
        }
    }

    return Demo()
}

#Preview("MissionCardContent - All Status") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(MissionStatus.allCases, id: \.self) { status in
                VStack(alignment: .leading, spacing: 8) {
                    Text(status.displayText)
                        .appFont(.title3, color: .gray)
                    MissionCardContent(
                        missionTitle: "SwiftUI 기초 학습",
                        status: status,
                        submissionType: .link,
                        linkText: "",
                        onSubmissionTypeChanged: { _ in },
                        onLinkTextChanged: { _ in },
                        onSubmit: { _, _ in }
                    )
                    .padding()
                    .background(Color.grey000)
                    .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
                }
            }
        }
        .padding()
    }
    .background(Color.grey100)
}
#endif
