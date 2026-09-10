//
//  CommunityThreadCreateView.swift
//  CommunityPresentation
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "스레드 만들기"

    static let titleLabel = "스레드 제목"
    static let descriptionLabel = "스레드 특징"
    static let descriptionHint = "어떤 스레드인지 한 줄로 알려 주세요."
    static let iconLabel = "스레드 아이콘"
    static let iconHint = "이모지 키보드에서 이모지 하나를 고르세요. 비워 두면 카테고리 기본 이모지를 씁니다."
    static let categoryLabel = "카테고리"
    static let categoryHint = "탭하면 카테고리를 고를 수 있어요."

    static let categoryImage = "chevron.up.chevron.down"
    static let errorImage = "exclamationmark.triangle"

    /// 이모지 한 칸이 아이콘처럼 보이도록 본문보다 크게 잡는다.
    static let iconFontSize: CGFloat = 34
    /// 이모지 한 글자만 들어가는 칸이라 카테고리 쪽에 폭을 양보한다.
    static let iconFieldWidth: CGFloat = 52
}

/// 스레드 생성 화면.
///
/// 아이콘은 앱 자체 이모지 그리드를 만들지 않고 iOS 순정 이모지 키보드에 맡긴다. `String`
/// 바인딩 `TextField` 는 adaptive image glyph 를 지원하지 않는다고 시스템에 알리므로
/// Genmoji·Memoji 가 후보로 뜨지 않고, 표준 유니코드 이모지만 들어온다.
///
/// 실측(#1132 · iPhone 17 Pro 시뮬레이터 · iOS 26.5): 이 칸의 이모지 키보드에는 카테고리
/// 바(ABC·자주 쓰는·스마일리·동물·음식·활동·여행·사물·기호·깃발)만 있고 Memoji 스티커 칸도
/// Genmoji 생성 버튼도 없었다. 단, 이 시뮬레이터에는 Image Playground 가 설치돼 있지 않아
/// Genmoji 는 애초에 뜰 수 없는 환경이었으므로 Genmoji 쪽은 실기기 재확인이 필요하다.
///
/// 키보드가 무엇을 내주든 서버로 나가는 값은 `CommunityThreadCreateRule.normalizedIcon(_:)`
/// 이 이모지 한 글자로 고정한다 — Genmoji 가 남기는 U+FFFC 도 여기서 걸린다. 그 규칙은
/// `CommunityThreadCreateRuleTests` 가 붙들고 있다.
struct CommunityThreadCreateView: View {

    // MARK: - Property

    @State private var viewModel: CommunityThreadCreateViewModel

    private let onCreated: (CommunityThread) -> Void

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool

    /// "이모지 변경하기" 가 이모지 키보드를 바로 띄우게 하는 통로.
    @FocusState private var isIconFocused: Bool

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
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                composer

                if let message = viewModel.submitErrorMessage {
                    errorLabel(message)
                }
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.top, DefaultSpacing.spacing24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.grey000)
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { submitButton }
        .safeAreaInset(edge: .bottom) { classificationSection }
        .sheet(isPresented: $viewModel.isCategorySheetPresented) {
            ThreadCategorySheet(
                selection: $viewModel.category,
                recommended: viewModel.recommendedCategory
            )
        }
    }

    // MARK: - View Component

    /// 제목과 특징을 한 덩어리로 묶은 입력부. 둘 사이의 구분선 말고는 장식을 두지 않는다.
    private var composer: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            ArticleTextField(
                placeholder: .threadTitle,
                text: $viewModel.title,
                focused: $isTitleFocused,
                submitLabel: .next,
                onSubmit: { isDescriptionFocused = true }
            )
            .accessibilityLabel(Constants.titleLabel)

            Divider()

            ArticleTextField(
                placeholder: .threadDescription,
                text: $viewModel.threadDescription,
                focused: $isDescriptionFocused
            )
            .accessibilityLabel(Constants.descriptionLabel)
            .accessibilityHint(Constants.descriptionHint)
        }
    }

    /// 화면 아래에 붙는 분류 카드. 수동 선택 칸은 자동 분류로 해결되지 않는 상태에서만 따라 나온다.
    private var classificationSection: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            ThreadClassificationCard(viewModel: viewModel) { isIconFocused = true }

            if viewModel.isManualSelectionVisible {
                manualSelection
            }
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .padding(.bottom, DefaultSpacing.spacing12)
    }

    private var manualSelection: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            iconField
                .frame(width: Constants.iconFieldWidth)

            categoryRow
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .padding(.vertical, DefaultSpacing.spacing12)
        .glassEffect(
            .regular,
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
    }

    private var iconField: some View {
        TextField(
            "",
            text: $viewModel.icon,
            prompt: Text(viewModel.iconPlaceholder)
        )
        .font(.system(size: Constants.iconFontSize))
        .multilineTextAlignment(.center)
        .focused($isIconFocused)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .submitLabel(.done)
        .accessibilityLabel(Constants.iconLabel)
        .accessibilityHint(Constants.iconHint)
    }

    private var categoryRow: some View {
        Button {
            viewModel.isCategorySheetPresented = true
        } label: {
            HStack(spacing: DefaultSpacing.spacing4) {
                Text(viewModel.category.displayName)
                    .appFont(.subheadline, color: .grey900)

                Image(systemName: Constants.categoryImage)
                    .foregroundStyle(Color.grey600)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Constants.categoryLabel)
        .accessibilityValue(viewModel.category.displayName)
        .accessibilityHint(Constants.categoryHint)
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
