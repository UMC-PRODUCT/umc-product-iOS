//
//  OperatorStudyReviewSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

struct OperatorStudyReviewSheet: View {
    // MARK: - Property

    @Environment(\.openURL) private var openURL

    @FocusState private var focusedID: UUID?
    @State private var feedback: String = ""

    let member: StudyMemberItem
    let onApprove: (String) -> Void
    let onReject: (String) -> Void

    fileprivate enum Constants {
        static let minSheetHeight: CGFloat = 420
        static let feedbackMinHeight: CGFloat = 350
        static let placeholderTopPadding: CGFloat = 8
        static let placeholderLeadingPadding: CGFloat = 4
        static let feedbackFieldID = UUID()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                submissionURLSection
                feedbackSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("\(member.week)주차 \(member.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.RejectBtn(action: {
                    onReject(feedback)
                })

                ToolBarCollection.ConfirmBtn(action: {
                    onApprove(feedback)
                })
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .keyboardDismissToolbar(focusedID: $focusedID)
    }

    // MARK: - View Components

    private var headerSection: some View {
        Text("\(member.displayName)님의 \(member.week)주차 스터디입니다.")
            .appFont(.subheadline, color: .grey600)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, DefaultConstant.sectionLeadingHeader)
    }

    private var submissionURLSection: some View {
        Section {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(verbatim: member.submissionURL ?? "URL이 등록되지 않았습니다.")
                    .appFont(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let urlString = member.submissionURL,
                   let url = URL(string: urlString) {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.up.right")
                            .renderingMode(.template)
                            .foregroundStyle(.gray)
                    }
                }
            }
        } header: {
            SectionHeaderView(title: "제출 URL")
        }
    }

    private var feedbackSection: some View {
        Section {
            TextEditor(text: $feedback)
                .focused($focusedID, equals: Constants.feedbackFieldID)
                .frame(minHeight: Constants.feedbackMinHeight)
                .overlay(alignment: .topLeading) {
                    if feedback.isEmpty {
                        Text("피드백을 작성해주세요.")
                            .appFont(.subheadline, color: .grey400)
                            .padding(.top, Constants.placeholderTopPadding)
                            .padding(.leading, Constants.placeholderLeadingPadding)
                            .allowsHitTesting(false)
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
