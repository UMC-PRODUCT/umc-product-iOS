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

    static let titleLabel = "스레드 제목"
    static let descriptionLabel = "스레드 특징"
    static let descriptionHint = "어떤 스레드인지 한 줄로 알려 주세요."
    static let iconLabel = "스레드 아이콘"
    static let iconHint = "이모지 키보드에서 이모지 하나를 고르세요. 비워 두면 카테고리 기본 이모지를 씁니다."

    static let deleteTitle = "스레드 삭제"
    static let deleteFooter = "삭제하면 대화 내용과 참여자가 모두 사라져요. 되돌릴 수 없어요."

    static let editImage = "pencil"
    static let deleteImage = "trash"
    static let errorImage = "exclamationmark.triangle"

    static let iconBadgeSize: CGFloat = 72
    static let iconFontSize: CGFloat = 34
    static let editBadgeSize: CGFloat = 24
    static let editImageSize: CGFloat = 11
    static let editBadgeBorderWidth: CGFloat = 2
    static let focusBorderWidth: CGFloat = 2
    /// 비어 있으면 저장될 카테고리 기본 이모지를 흐리게 보여 준다 — 입력값이 아님을 드러낸다.
    static let placeholderOpacity: Double = 0.4
    static let pressedScale: CGFloat = 0.97
    static let pressDuration: TimeInterval = 0.1
    /// 파괴적 행이 손가락에 충분히 걸리도록 하는 최소 높이 (HIG).
    static let destructiveRowHeight: CGFloat = 44
    static let valueSpringDuration: TimeInterval = 0.35
    static let valueFadeDuration: TimeInterval = 0.2
}

/// 스레드 편집 화면.
///
/// 생성 화면(#1313)과 같은 컴포저·같은 분류 카드를 쓴다 — 만들 때와 고칠 때의 화면이 다르면
/// 어떤 값이 무엇이었는지 다시 배워야 한다. 편집에만 있는 건 세 가지다: 이미 정해진 아이콘을
/// 보여 주는 배지, 특징을 고쳤을 때 카드가 띄우는 재분류 넛지(#11), 맨 아래 삭제(#09).
struct CommunityThreadEditView: View {

    // MARK: - Property

    @State private var viewModel: CommunityThreadEditViewModel

    private let onUpdated: (CommunityThread) -> Void

    /// 삭제가 끝났을 때 리스트에 알린다. 실시간 `thread.deleted` 로도 행이 지워지지만,
    /// 그걸 기다리면 되돌아온 리스트에 방금 지운 스레드가 잠깐 남아 있다.
    private let onDeleted: (String) -> Void

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var isIconFocused: Bool

    @State private var iconDraft = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                iconBadge

                composer

                if let message = viewModel.submitErrorMessage {
                    errorLabel(message)
                }

                ThreadClassificationCard(
                    viewModel: viewModel,
                    editing: .init(
                        icon: viewModel.effectiveIcon,
                        category: viewModel.category,
                        isReclassifySuggested: viewModel.isReclassifySuggested,
                        onSelectCategory: { viewModel.isCategorySheetPresented = true }
                    )
                )

                deleteSection
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.vertical, DefaultSpacing.spacing24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.grey000)
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { submitButton }
        .sensoryFeedback(.success, trigger: viewModel.classification.isLoading) { _, isLoading in
            !isLoading && viewModel.classification.value != nil
        }
        .sheet(isPresented: $viewModel.isCategorySheetPresented) {
            ThreadCategorySheet(
                selection: $viewModel.category,
                recommended: viewModel.recommendedCategory
            )
        }
        .alertPrompt(item: $viewModel.alertPrompt)
        .onChange(of: viewModel.didDelete) { _, didDelete in
            guard didDelete else { return }
            onDeleted(viewModel.original.id)
            dismiss()
        }
    }

    // MARK: - View Component

    /// 이모지 키보드를 여는 배지. 입력은 뒤에 숨긴 칸이 받고, 배지는 포커스만 옮긴다 —
    /// 이모지 한 글자를 받는 칸을 그대로 드러내면 커서·선택 핸들이 아이콘을 가린다.
    private var iconBadge: some View {
        ZStack {
            iconField

            Button {
                isIconFocused = true
            } label: {
                iconBadgeLabel
            }
            .buttonStyle(IconBadgeButtonStyle())
            .disabled(viewModel.classification.isLoading)
            .accessibilityLabel(Constants.iconLabel)
            .accessibilityValue(viewModel.effectiveIcon)
            .accessibilityHint(Constants.iconHint)
        }
    }

    private var iconBadgeLabel: some View {
        Text(viewModel.icon.isEmpty ? viewModel.iconPlaceholder : viewModel.icon)
            .font(.system(size: Constants.iconFontSize))
            .opacity(viewModel.icon.isEmpty ? Constants.placeholderOpacity : 1)
            .contentTransition(.opacity)
            .animation(valueAnimation, value: viewModel.effectiveIcon)
            .frame(width: Constants.iconBadgeSize, height: Constants.iconBadgeSize)
            .background(Color.grey100, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(
                        isIconFocused ? Color.indigo500 : .clear,
                        lineWidth: Constants.focusBorderWidth
                    )
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: Constants.editImage)
                    .font(.system(size: Constants.editImageSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: Constants.editBadgeSize, height: Constants.editBadgeSize)
                    .background(Color.indigo500, in: .circle)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.grey000, lineWidth: Constants.editBadgeBorderWidth)
                    }
            }
            .contentShape(.rect)
    }

    private var iconField: some View {
        TextField("", text: $iconDraft)
            .focused($isIconFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .frame(width: Constants.iconBadgeSize, height: Constants.iconBadgeSize)
            .opacity(0)
            .accessibilityHidden(true)
            // 글자 하나에도 정규화가 "" 를 돌려줘 아이콘이 바뀌므로, 지우기·이모지만 받고 칸을 되돌린다.
            .onChange(of: iconDraft) { _, draft in
                if draft.isEmpty || !CommunityThreadCreateRule.normalizedIcon(draft).isEmpty {
                    viewModel.icon = draft
                }
                iconDraft = viewModel.icon
            }
            .onChange(of: viewModel.icon, initial: true) { _, icon in iconDraft = icon }
    }

    /// 제목과 특징을 한 덩어리로 묶은 입력부. 생성 화면과 같은 모양이다.
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

    private func errorLabel(_ message: String) -> some View {
        Label(message, systemImage: Constants.errorImage)
            .appFont(.footnote, color: Color.red500)
    }

    /// 삭제는 저장 버튼과 멀리 떨어진 맨 아래에, 휴지통 아이콘까지 달아 둔다 — 색만으로
    /// 구분하면 색각 이상·고대비 설정에서 평범한 행과 같아 보인다.
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Button(role: .destructive) {
                viewModel.confirmDelete()
            } label: {
                Label(Constants.deleteTitle, systemImage: Constants.deleteImage)
                    .appFont(.body, color: Color.red500)
                    .padding(.vertical, DefaultSpacing.spacing12)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: Constants.destructiveRowHeight,
                        alignment: .leading
                    )
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                    .background(
                        Color.grey100,
                        in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
                    )
                    .contentShape(.rect)
            }

            Text(Constants.deleteFooter)
                .appFont(.caption1, color: .grey600)
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
    }

    private var valueAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: Constants.valueFadeDuration)
            : .spring(duration: Constants.valueSpringDuration, bounce: 0)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var submitButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            // 바뀐 게 없거나(#10) 재분류가 도는 동안(#12) `canSubmit` 이 false 라 잠긴다.
            Button(role: .confirm, action: submit)
                .tint(.indigo500)
                .disabled(!viewModel.canSubmit)
                .accessibilityLabel(Constants.submitTitle)
        }
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

// MARK: - IconBadgeButtonStyle

private struct IconBadgeButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Constants.pressedScale : 1)
            .animation(
                .easeInOut(duration: Constants.pressDuration),
                value: configuration.isPressed
            )
    }
}
