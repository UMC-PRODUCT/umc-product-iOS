//
//  OperatorStudyReviewSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

struct OperatorStudyReviewSheet: View {
    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var feedback: String = ""
    @State private var showRejectAlert: Bool = false

    let member: StudyMemberItem
    let onApprove: (String) -> Void
    let onReject: (String) -> Void

    fileprivate enum Constants {
        static let feedbackMinHeight: CGFloat = 350
        static let placeholderTopPadding: CGFloat = 8
        static let placeholderLeadingPadding: CGFloat = 4
        static let closeIcon: String = "xmark"
        static let openLinkIcon: String = "arrow.up.right"
        static let confirmIcon: String = "checkmark"
        static let rejectIcon: String = "arrowshape.turn.up.left.2"
        static let rejectTitle: String = "스터디 반려"
        static let rejectMessageTemplate: String = "%@님의 %d주차 스터디를 반려하시겠습니까?"
        static let rejectPositive: String = "반려"
        static let cancel: String = "취소"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                submissionURLSection
                feedbackSection
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("\(member.week)주차 \(member.displayName)")
            .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            dismissButton

                actionButtons
            }
        }
        .presentationDetents([.fraction(0.9)])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .alert(Constants.rejectTitle, isPresented: $showRejectAlert) {
            Button(Constants.cancel, role: .cancel) {}
            Button(Constants.rejectPositive, role: .destructive) {
                confirmReject()
            }
        } message: {
            Text(String(format: Constants.rejectMessageTemplate, member.displayName, member.week))
        }
    }

    // MARK: - Action Buttons

    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: dismissAction) {
                Image(systemName: Constants.closeIcon)
            }
        }
    }

    private var actionButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            rejectButton
            approveButton
        }
    }

    private var rejectButton: some View {
        Button(action: rejectAction) {
            Image(systemName: Constants.rejectIcon)
        }
        .tint(.grey900)
    }

    private var approveButton: some View {
        Button(action: approveAction) {
            Image(systemName: Constants.confirmIcon)
        }
        .tint(.indigo500)
    }

    private func dismissAction() {
        dismiss()
    }

    private func rejectAction() {
        showRejectAlert = true
    }

    private func approveAction() {
        onApprove(feedback)
        dismiss()
    }

    private func confirmReject() {
        onReject(feedback)
        dismiss()
    }

    @ViewBuilder
    private var openSubmissionURLButton: some View {
        if let urlString = member.submissionURL,
           let url = URL(string: urlString) {
            Button {
                openURL(url)
            } label: {
                Image(systemName: Constants.openLinkIcon)
                    .renderingMode(.template)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var submissionURLText: some View {
        Text(verbatim: member.submissionURL ?? "URL이 등록되지 않았습니다.")
            .appFont(.subheadline)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var submissionURLRow: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            submissionURLText
            openSubmissionURLButton
        }
    }

    private var submissionURLHeader: some View {
        SectionHeaderView(title: "제출 URL")
    }

    // MARK: - View Components

    private var feedbackPlaceholder: some View {
        Text("피드백을 작성해주세요.")
            .appFont(.subheadline, color: Color(.placeholderText))
            .padding(.top, Constants.placeholderTopPadding)
            .padding(.leading, Constants.placeholderLeadingPadding)
            .allowsHitTesting(false)
    }

    private var submissionURLSection: some View {
        Section {
            submissionURLRow
        } header: {
            submissionURLHeader
        }
    }

    private var feedbackSection: some View {
        Section {
            TextEditor(text: $feedback)
                .frame(minHeight: Constants.feedbackMinHeight)
                .overlay(alignment: .topLeading) {
                    if feedback.isEmpty {
                        feedbackPlaceholder
                    }
                }
        }
    }

}

// MARK: - Preview

#if DEBUG
#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            OperatorStudyReviewSheet(
                member: StudyMemberItem(
                    serverID: "1",
                    name: "홍길동",
                    nickname: "닉네임",
                    part: .ios,
                    university: "중앙대",
                    studyTopic: "SwiftUI 심화",
                    week: 3,
                    submissionURL: "https://github.com/example/study"
                ),
                onApprove: { print("승인: \($0)") },
                onReject: { print("반려: \($0)") }
            )
        }
}
#endif
