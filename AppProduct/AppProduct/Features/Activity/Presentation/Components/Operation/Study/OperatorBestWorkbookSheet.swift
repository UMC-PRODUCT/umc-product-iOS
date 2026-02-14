//
//  OperatorBestWorkbookSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import SwiftUI

/// 베스트 워크북 선정 시트
///
/// 추천사를 입력받아 베스트 워크북으로 선정합니다.
struct OperatorBestWorkbookSheet: View {
    // MARK: - Property

    @FocusState private var focusedID: UUID?
    @State private var recommendation: String = ""

    /// 선정 대상 스터디원
    let member: StudyMemberItem
    /// 선정 완료 콜백 (추천사 전달)
    let onSelect: (String) -> Void

    fileprivate enum Constants {
        static let recommendationMinHeight: CGFloat = 120
        static let placeholderTopPadding: CGFloat = 8
        static let placeholderLeadingPadding: CGFloat = 4
        static let recommendationFieldID = UUID()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                recommendationSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("베스트 워크북 선정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn(action: {})

                ToolBarCollection.ConfirmBtn {
                    onSelect(recommendation)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .keyboardDismissToolbar(focusedID: $focusedID)
    }

    // MARK: - View Components

    private var recommendationSection: some View {
        Section {
            TextEditor(text: $recommendation)
                .focused($focusedID, equals: Constants.recommendationFieldID)
                .frame(minHeight: Constants.recommendationMinHeight)
                .overlay(alignment: .topLeading) {
                    if recommendation.isEmpty {
                        Text("이 스터디를 추천하는 이유를 작성하세요.")
                            .appFont(.subheadline, color: .grey400)
                            .padding(.top, Constants.placeholderTopPadding)
                            .padding(.leading, Constants.placeholderLeadingPadding)
                            .allowsHitTesting(false)
                    }
                }
        } header: {
            SectionHeaderView(
                title: "\(member.nickname)에게 전하는 추천사(커뮤니티 공개용)")
        } footer: {
            footerSection
        }
    }

    private var footerSection: some View {
        Text("우수한 스터디를 명예의 전당에 등록하고 \(member.displayName)님의 경고 점수를 차감할 수 있습니다.")
            .appFont(.subheadline, color: .grey600)
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
                onSelect: { print("선정: \($0)") }
            )
        }
}
#endif
