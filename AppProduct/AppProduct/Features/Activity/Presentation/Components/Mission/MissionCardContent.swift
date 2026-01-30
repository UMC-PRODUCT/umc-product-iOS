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
        MissionSubmissionView(
            submissionType: submissionType,
            linkText: linkText,
            onSubmissionTypeChanged: onSubmissionTypeChanged,
            onLinkTextChanged: onLinkTextChanged,
            onSubmit: onSubmit
        )
    }

    private var pendingApprovalView: some View {
        MissionStatusResultView(
            icon: "hourglass",
            message: "학습 완료 확인 대기 중입니다.",
            color: .orange
        )
    }

    private var passView: some View {
        MissionStatusResultView(
            icon: "checkmark.circle.fill",
            message: "해당 주차 스터디를 통과하였습니다.",
            color: .green
        )
    }

    private var failView: some View {
        MissionStatusResultView(
            icon: "xmark.circle.fill",
            message: "해당 주차 스터디를 통과하지 못했습니다.",
            color: .red
        )
    }
}

// MARK: - MissionSubmissionView

/// 미션 제출 UI (타입 선택 + 링크 입력 + 제출 버튼)
private struct MissionSubmissionView: View, Equatable {

    // MARK: - Property

    let submissionType: MissionSubmissionType
    let linkText: String
    let onSubmissionTypeChanged: (MissionSubmissionType) -> Void
    let onLinkTextChanged: (String) -> Void
    let onSubmit: (MissionSubmissionType, String?) -> Void

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.submissionType == rhs.submissionType &&
        lhs.linkText == rhs.linkText
    }

    // MARK: - Constants

    private enum Constants {
        static let submitButtonWidth: CGFloat = 80
        static let borderWidth: CGFloat = 1
    }

    // MARK: - Computed Property

    private var hasError: Bool {
        !linkText.isEmpty && !linkText.isValidHTTPURL
    }

    private var isSubmitDisabled: Bool {
        submissionType == .link && !linkText.isValidHTTPURL
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            typeSelectionSection
            submissionSection
        }
    }

    // MARK: - View Components

    private var typeSelectionSection: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            ForEach(MissionSubmissionType.allCases, id: \.self) { type in
                ChipButton(
                    type.rawValue,
                    isSelected: submissionType == type,
                    leadingIcon: type.icon
                ) {
                    withAnimation(.easeInOut(duration: DefaultConstant.animationTime)) {
                        onSubmissionTypeChanged(type)
                    }
                }
                .buttonSize(.small)
            }
        }
    }

    private var submissionSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(spacing: DefaultSpacing.spacing12) {
                if submissionType == .link {
                    linkInput
                }

                SubmitButton(
                    isDisabled: isSubmitDisabled,
                    onSubmit: {
                        if submissionType == .link {
                            onSubmit(.link, linkText)
                        } else {
                            onSubmit(.completeOnly, nil)
                        }
                    }
                )
                .frame(
                    maxWidth: submissionType == .link
                        ? Constants.submitButtonWidth : .infinity
                )
            }

            if submissionType == .link && hasError {
                Text("올바른 URL 형식이 아닙니다")
                    .appFont(.footnote, color: .red)
            }
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
                .strokeBorder(
                    hasError ? Color.red : Color.grey300,
                    lineWidth: Constants.borderWidth)
        )
    }
}

// MARK: - MissionStatusResultView

/// 미션 상태 결과 뷰 (아이콘 + 메시지 + 배경)
fileprivate struct MissionStatusResultView: View, Equatable {

    // MARK: - Property

    let icon: String
    let message: String
    let color: Color

    private enum Constants {
        static let padding: EdgeInsets = .init(
            top: 14, leading: 12, bottom: 14, trailing: 12)
        static let backgroundOpacity: Double = 0.15
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .appFont(.callout, color: color)
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity)
        .background(
            color.opacity(Constants.backgroundOpacity),
            in: RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
        )
    }
}

// MARK: - SubmitButton

/// 미션 제출 버튼 (공통 스타일)
fileprivate struct SubmitButton: View, Equatable {

    // MARK: - Property

    let isDisabled: Bool
    let onSubmit: () -> Void

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isDisabled == rhs.isDisabled
    }

    // MARK: - Body

    var body: some View {
        Button {
            onSubmit()
        } label: {
            Text("제출")
                .appFont(.subheadline, weight: .bold, color: .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .tint(.indigo500)
        .disabled(isDisabled)
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
