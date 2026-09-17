//
//  CommunityThreadEditView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "스레드 편집"
    static let submitTitle = "저장"

    static let moreMenuLabel = "더 보기"
    static let deleteTitle = "스레드 삭제"

    static let moreMenuImage = "ellipsis"
    static let deleteImage = "trash"
}

/// 스레드 편집 화면.
///
/// 입력 폼은 생성 화면(#1313)과 같은 ``ThreadForm`` 을 쓴다 — 만들 때와 고칠 때의 화면이 다르면
/// 어떤 값이 무엇이었는지 다시 배워야 한다. 편집에만 있는 건 두 가지다: 특징을 고쳤을 때 분류
/// 카드가 띄우는 재분류 넛지(#11), 툴바 `더 보기` 메뉴 안의 삭제(#09).
struct CommunityThreadEditView: View {

    // MARK: - Property

    @State private var viewModel: CommunityThreadEditViewModel

    private let onUpdated: (CommunityThread) -> Void

    /// 삭제가 끝났을 때 리스트에 알린다. 실시간 `thread.deleted` 로도 행이 지워지지만,
    /// 그걸 기다리면 되돌아온 리스트에 방금 지운 스레드가 잠깐 남아 있다.
    private let onDeleted: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(
        viewModel: CommunityThreadEditViewModel,
        onUpdated: @escaping (CommunityThread) -> Void,
        onDeleted: @escaping (String) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
    }

    // MARK: - Body

    var body: some View {
        ThreadForm(
            viewModel: viewModel,
            classificationMode: .edit(isReclassifySuggested: viewModel.isReclassifySuggested),
            showsCategoryRow: true
        ) {}
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        // 고치는 중 다른 탭으로 넘어가면 바뀐 값을 잃는다 — 생성 화면과 같이 탭 바를 숨긴다.
        .toolbarVisibility(.hidden, for: .tabBar)
        .alertPrompt(item: $viewModel.alertPrompt)
        .onChange(of: viewModel.didDelete) { _, didDelete in
            guard didDelete else { return }
            onDeleted(viewModel.original.id)
            dismiss()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            moreMenu
        }

        // 메뉴와 저장이 한 유리 캡슐로 붙으면 한 덩어리로 읽혀, 저장하려다 메뉴를 누르기 쉽다.
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .confirmationAction) {
            // 바뀐 게 없거나(#10) 재분류가 도는 동안(#12) `canSubmit` 이 false 라 잠긴다.
            Button(role: .confirm, action: submit)
                .tint(.indigo500)
                .disabled(!viewModel.canSubmit)
                .accessibilityLabel(Constants.submitTitle)
        }
    }

    /// 삭제는 저장 옆에 바로 두지 않고 메뉴 안에 접는다 — 되돌릴 수 없는 작업이 한 번의 탭에
    /// 닿지 않게 한다. 확인은 `confirmDelete()` 의 `AlertPrompt` 가 한 번 더 받는다.
    private var moreMenu: some View {
        Menu {
            Button(role: .destructive) {
                viewModel.confirmDelete()
            } label: {
                Label(Constants.deleteTitle, systemImage: Constants.deleteImage)
            }
            .accessibilityLabel(Constants.deleteTitle)
        } label: {
            Image(systemName: Constants.moreMenuImage)
        }
        .accessibilityLabel(Constants.moreMenuLabel)
    }

    // MARK: - Function

    private func submit() {
        Task {
            guard let thread = await viewModel.submit() else { return }
            onUpdated(thread)
            dismiss()
        }
    }
}
