//
//  OperatorBestWorkbookSheet.swift
//  AppProduct
//
//  Created by euijjang97 on 2/18/26.
//

import SwiftUI

/// 베스트 워크북 선정 시트
///
/// 추천사를 입력받아 베스트 워크북으로 선정합니다.
struct OperatorBestWorkbookSheet: View {
    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var recommendation: String = ""
    @State private var isSubmitting = false

    /// 선정 대상 스터디원
    let member: StudyMemberItem
    /// 선정 완료 콜백 (추천사 전달)
    let onSelect: (String) async -> Bool

    fileprivate enum Constants {
        static let avatarSize: CGFloat = 48
        static let recommendationMinHeight: CGFloat = 120
        static let placeholderTopPadding: CGFloat = 8
        static let placeholderLeadingPadding: CGFloat = 4
        static let sectionSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let sectionPadding: CGFloat = 14
        static let sectionCornerRadius: CGFloat = 16
        static let sectionTopPadding: CGFloat = 12
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.sectionSpacing) {
                    profileSection
                    recommendationSection
                    footerSection
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.top, Constants.sectionTopPadding)
                .padding(.bottom, DefaultSpacing.spacing16)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("베스트 워크북 선정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn(action: {})
                ToolBarCollection.ConfirmBtn(
                    action: submitSelection,
                    isLoading: isSubmitting,
                    dismissOnTap: false
                )
            }
        }
        .presentationDetents([.fraction(0.7)])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    // MARK: - View Components

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            SectionHeaderView(
                title: "\(member.nickname)에게 전하는 추천사(커뮤니티 공개용)"
            )

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Constants.sectionCornerRadius)
                    .fill(Color.grey100)

                TextEditor(text: $recommendation)
                    .frame(minHeight: Constants.recommendationMinHeight)
                    .padding(.horizontal, Constants.sectionPadding)
                    .padding(.top, Constants.sectionPadding)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                if recommendation.isEmpty {
                    Text("이 스터디를 추천하는 이유를 작성하세요.")
                        .appFont(.subheadline, color: Color(.placeholderText))
                        .padding(
                            .init(
                                top: Constants.sectionPadding + Constants.placeholderTopPadding,
                                leading: Constants.sectionPadding + Constants.placeholderLeadingPadding,
                                bottom: 0,
                                trailing: 0
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: Constants.recommendationMinHeight)
            .clipShape(RoundedRectangle(cornerRadius: Constants.sectionCornerRadius))
        }
    }

    private var footerSection: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.green)

            Text("우수한 스터디를 명예의 전당에 등록하고 \(member.displayName)님의 경고 점수를 차감할 수 있습니다.")
                .appFont(.subheadline, color: .green700)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Constants.sectionPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.sectionCornerRadius)
                .fill(.green.opacity(0.1))
        )
    }

    private var profileSection: some View {
        HStack(spacing: Constants.sectionPadding) {
            RemoteImage(
                urlString: member.profileImageURL ?? "",
                size: CGSize(
                    width: Constants.avatarSize,
                    height: Constants.avatarSize
                ),
                cornerRadius: 0,
                placeholderImage: "person.fill"
            )
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(member.nickname)
                    .appFont(.subheadline, color: .grey900)

                Text(member.displayName)
                    .appFont(.footnote, color: .grey600)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(Constants.sectionPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.sectionCornerRadius)
                .fill(Color.grey100)
        )
    }
}

private extension OperatorBestWorkbookSheet {
    private func submitSelection() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            let isSuccess = await onSelect(recommendation)
            isSubmitting = false

            if isSuccess {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            OperatorBestWorkbookSheet(
                member: StudyMemberItem(
                    serverID: "1",
                    name: "홍길동",
                    nickname: "닉네임",
                    part: .ios,
                    university: "중앙대",
                    studyTopic: "SwiftUI 심화",
                    week: 3
                ),
                onSelect: { recommendation in
                    print("선정: \(recommendation)")
                    return true
                }
            )
        }
}
#endif
