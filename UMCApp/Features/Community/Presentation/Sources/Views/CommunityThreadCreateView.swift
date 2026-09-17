//
//  CommunityThreadCreateView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import SwiftUI
import ActivityPresentation
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "스레드 만들기"

    static let inviteeLabel = "초대할 챌린저"
    static let inviteeEmptyValue = "선택 안 함"
    static let inviteeHint = "탭하면 초대할 챌린저를 고를 수 있어요."

    static let inviteeImage = "chevron.right"
    static let errorImage = "exclamationmark.triangle"
}

/// 스레드 생성 화면.
///
/// 입력 폼은 편집 화면과 같은 ``ThreadForm`` 을 쓴다(아이콘 입력 방식과 그 실측 메모도 거기 있다).
/// 생성에만 있는 건 폼 맨 아래 초대할 챌린저 섹션이다.
struct CommunityThreadCreateView: View {

    // MARK: - Property

    @State private var viewModel: CommunityThreadCreateViewModel

    private let onCreated: (CommunityThread) -> Void

    @State private var isInviteePickerPresented = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(
        viewModel: CommunityThreadCreateViewModel,
        onCreated: @escaping (CommunityThread) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
    }

    // MARK: - Body

    var body: some View {
        ThreadForm(
            viewModel: viewModel,
            classificationMode: .create,
            showsCategoryRow: viewModel.isManualSelectionVisible
        ) {
            inviteeSection
        }
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { submitButton }
        // 작성 중 다른 탭으로 넘어가면 초안을 잃는다 — 스레드 방 화면과 같이 탭 바를 숨긴다.
        .toolbarVisibility(.hidden, for: .tabBar)
    }

    // MARK: - View Component

    /// 초대 행과, 상한에 걸렸을 때만 나오는 안내를 한 섹션에 둔다.
    private var inviteeSection: some View {
        Section {
            inviteeRow

            if let notice = viewModel.inviteeCapacityNotice {
                errorLabel(notice)
            }
        }
    }

    /// 생성과 동시에 초대할 챌린저를 고르는 행.
    ///
    /// 선택 시트는 Activity 의 `SelectedChallengerView` 를 그대로 쓴다 — 일정 등록의 참여자
    /// 선택(`ScheduleRegistrationView`)이 이미 같은 방식으로 재사용하고 있다. 그쪽은 개수
    /// 제한을 모르므로 상한은 ViewModel 이 되쓸 때 자른다.
    private var inviteeRow: some View {
        Button {
            isInviteePickerPresented = true
        } label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(Constants.inviteeLabel)
                    .appFont(.body, color: Color.grey900)

                Spacer(minLength: 0)

                Text(inviteeValue)
                    .appFont(.callout, color: Color.grey500)

                Image(systemName: Constants.inviteeImage)
                    .foregroundStyle(Color.grey500)
            }
        }
        .accessibilityLabel(Constants.inviteeLabel)
        .accessibilityValue(inviteeValue)
        .accessibilityHint(Constants.inviteeHint)
        .sheet(isPresented: $isInviteePickerPresented) {
            SelectedChallengerView(challenger: $viewModel.invitees)
                .presentationDragIndicator(.visible)
        }
    }

    /// 상한 안내는 여기 두지 않는다 — 상한에 걸렸을 때만 `inviteeCapacityNotice` 가 알린다.
    private var inviteeValue: String {
        viewModel.invitees.isEmpty
            ? Constants.inviteeEmptyValue
            : "\(viewModel.invitees.count)명"
    }

    private func errorLabel(_ message: String) -> some View {
        Label(message, systemImage: Constants.errorImage)
            .appFont(.footnote, color: Color.red500)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var submitButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            // 전송 중에는 `canSubmit` 이 false 라 버튼이 잠긴다 — 중복 제출은 여기서 막힌다.
            Button(role: .confirm, action: submit)
                .tint(.indigo500)
                .disabled(!viewModel.canSubmit)
                .accessibilityLabel(Constants.navigationTitle)
        }
    }

    // MARK: - Function

    private func submit() {
        Task {
            guard let thread = await viewModel.submit() else { return }
            onCreated(thread)
            dismiss()
        }
    }
}
