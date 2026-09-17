//
//  ThreadForm.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/17/26.
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    static let previewHeader = "미리보기"
    static let titleHeader = "제목"
    static let descriptionHeader = "특징"
    static let iconHeader = "아이콘"
    static let classificationHeader = "카테고리 분류"

    static let untitledPreview = "이름 없는 스레드"

    static let titleLabel = "스레드 제목"
    static let descriptionLabel = "스레드 특징"
    static let descriptionHint = "어떤 스레드인지 한 줄로 알려 주세요."
    static let customIconLabel = "다른 이모지"
    static let customIconHint = "이모지 키보드에서 이모지 하나를 고르세요. 비워 두면 카테고리 기본 이모지를 씁니다."
    static let selectedValue = "선택됨"
    static let unselectedValue = "선택 안 됨"
    static let categoryLabel = "카테고리"
    static let categoryHint = "탭하면 카테고리를 고를 수 있어요."

    static let customIconImage = "face.smiling"
    static let categoryImage = "chevron.up.chevron.down"
    static let errorImage = "exclamationmark.triangle"

    /// 카테고리 기본 이모지를 앞에 둔다 — 아이콘을 비워 둔 상태가 그중 한 칸의 선택으로 보인다.
    /// 뒤에 붙인 것도 모두 `normalizedIcon` 을 그대로 통과하는 이모지 한 글자여야 한다.
    static let suggestedIcons: [String] = CommunityThreadCategory.allCases.map(\.defaultIcon)
        + ["💡", "💻", "📱", "🎨", "🎯", "🔥", "🎉"]

    /// 이모지 한 칸의 지름. 최소 터치 타깃(HIG 44pt)과 맞춘다.
    static let iconCellSize: CGFloat = 44
    static let iconCellFontSize: CGFloat = 28
    static let selectionBorderWidth: CGFloat = 2
    /// 비어 있으면 저장될 값을 흐리게 보여 준다 — 입력값이 아님을 드러낸다.
    static let placeholderOpacity: Double = 0.4
}

/// 스레드 생성·편집 화면이 함께 쓰는 입력 폼.
///
/// 만들 때와 고칠 때의 화면이 다르면 어떤 값이 무엇이었는지 다시 배워야 한다. 그래서 섹션 구성
/// (미리보기 → 제목 → 특징 → 아이콘 → 카테고리 분류)을 여기 한 곳에 두고, 화면은 자기에게만
/// 있는 섹션을 `trailing` 으로 덧붙인다.
///
/// 아이콘은 추천 이모지 몇 개만 앱이 보여 주고, 나머지는 iOS 순정 이모지 키보드에 맡긴다.
/// `String` 바인딩 `TextField` 는 adaptive image glyph 를 지원하지 않는다고 시스템에 알리므로
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
struct ThreadForm<ViewModel: ThreadFormPresenting, Trailing: View>: View {

    // MARK: - Property

    @Bindable private var viewModel: ViewModel

    private let classificationMode: ThreadClassificationCard.Mode

    /// 카테고리를 손으로 고르는 행을 띄울지. 생성 화면은 분류 전 첫 화면을 어지럽히지 않으려고
    /// 조건부로 켠다.
    private let showsCategoryRow: Bool

    private let trailing: Trailing

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var isIconFocused: Bool

    @State private var iconDraft = ""

    /// 스레드 리스트 행의 아이콘 타일과 같은 비율로 커진다.
    @ScaledMetric(relativeTo: .title2)
    private var scaledPreviewIconSize = ThreadCardMetrics.iconSize

    // MARK: - Init

    init(
        viewModel: ViewModel,
        classificationMode: ThreadClassificationCard.Mode,
        showsCategoryRow: Bool,
        @ViewBuilder trailing: () -> Trailing
    ) {
        _viewModel = Bindable(viewModel)
        self.classificationMode = classificationMode
        self.showsCategoryRow = showsCategoryRow
        self.trailing = trailing()
    }

    // MARK: - Body

    var body: some View {
        Form {
            submitErrorSection

            previewSection

            titleSection

            descriptionSection

            iconSection

            classificationSection

            trailing
        }
        .scrollDismissesKeyboard(.interactively)
        // 섹션 묶음이 아니라 Form 에 한 번만 건다 — 묶음에 걸면 자식 섹션마다 따로 울린다.
        .sensoryFeedback(.success, trigger: viewModel.classification.isLoading) { _, isLoading in
            !isLoading && viewModel.classification.value != nil
        }
        .sheet(isPresented: $viewModel.isCategorySheetPresented) {
            ThreadCategorySheet(
                selection: $viewModel.category,
                recommended: viewModel.recommendedCategory
            )
        }
    }

    // MARK: - Computed Property

    /// 지금 저장될 아이콘. 비워 두면 카테고리 기본 이모지가 채운다.
    private var selectedIcon: String {
        viewModel.icon.isEmpty ? viewModel.iconPlaceholder : viewModel.icon
    }

    /// 키보드로 고른 이모지가 추천 칸에 없으면 `다른 이모지` 칸이 그 이모지를 대신 보여 준다.
    private var isCustomIconSelected: Bool {
        !Constants.suggestedIcons.contains(selectedIcon)
    }

    private var trimmedTitle: String {
        viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        viewModel.threadDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewTitle: String {
        trimmedTitle.isEmpty ? Constants.untitledPreview : trimmedTitle
    }

    private var previewAccessibilityLabel: String {
        [
            Constants.previewHeader,
            selectedIcon,
            previewTitle,
            viewModel.category.displayName,
            trimmedDescription
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    // MARK: - Submit Error Section

    /// 제출 실패 메시지. 일정 등록 화면처럼 폼 맨 위 섹션에 띄워 입력부보다 먼저 읽히게 한다.
    @ViewBuilder
    private var submitErrorSection: some View {
        if let message = viewModel.submitErrorMessage {
            Section {
                Label(message, systemImage: Constants.errorImage)
                    .appFont(.footnote, color: Color.red500)
            }
        }
    }

    // MARK: - Preview Section

    /// 리스트에 올라갈 모습. 저장 전 값을 스레드 리스트 행과 같은 배치로 미리 보여 준다.
    private var previewSection: some View {
        Section {
            HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
                previewIcon

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    HStack(spacing: DefaultSpacing.spacing4) {
                        Text(previewTitle)
                            .appFont(.subheadline, weight: .semibold, color: .grey900)
                            .lineLimit(1)
                            .opacity(trimmedTitle.isEmpty ? Constants.placeholderOpacity : 1)
                            // 칩이 먼저 자리를 가져가면 제목이 말줄임만 남는다.
                            .layoutPriority(1)

                        ThreadCategoryChip(category: viewModel.category)

                        Spacer(minLength: 0)
                    }

                    if !trimmedDescription.isEmpty {
                        Text(trimmedDescription)
                            .appFont(.footnote, color: .grey500)
                            .lineLimit(1)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(previewAccessibilityLabel)
        } header: {
            Text(Constants.previewHeader)
        }
    }

    private var previewIcon: some View {
        Text(selectedIcon)
            .font(.app(.title2))
            .opacity(viewModel.icon.isEmpty ? Constants.placeholderOpacity : 1)
            .frame(
                width: min(scaledPreviewIconSize, ThreadCardMetrics.maxIconSize),
                height: min(scaledPreviewIconSize, ThreadCardMetrics.maxIconSize)
            )
            .background(Color.grey100, in: .circle)
    }

    // MARK: - Input Section

    private var titleSection: some View {
        Section {
            ArticleTextField(
                placeholder: .threadTitle,
                text: $viewModel.title,
                focused: $isTitleFocused,
                submitLabel: .next,
                onSubmit: { isDescriptionFocused = true }
            )
            .accessibilityLabel(Constants.titleLabel)
        } header: {
            Text(Constants.titleHeader)
        }
    }

    private var descriptionSection: some View {
        Section {
            ArticleTextField(
                placeholder: .threadDescription,
                text: $viewModel.threadDescription,
                focused: $isDescriptionFocused
            )
            .accessibilityLabel(Constants.descriptionLabel)
            .accessibilityHint(Constants.descriptionHint)
        } header: {
            Text(Constants.descriptionHeader)
        }
    }

    // MARK: - Icon Section

    /// 추천 이모지 그리드와, 키보드로 아무 이모지나 고르는 마지막 칸.
    ///
    /// 한 행에 버튼이 여럿이라 칸마다 `.plain` 스타일을 건다 — 기본 스타일이면 Form 이 행 탭 한
    /// 번에 행 안의 버튼을 전부 누른다.
    private var iconSection: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.iconCellSize))],
                spacing: DefaultSpacing.spacing12
            ) {
                ForEach(Constants.suggestedIcons, id: \.self) { emoji in
                    suggestedIconCell(emoji)
                }

                customIconCell
            }
            .padding(.vertical, DefaultSpacing.spacing4)
            // 분류가 끝나면 결과가 아이콘을 덮어쓰므로, 그 사이에 고른 이모지는 사라진다.
            .disabled(viewModel.classification.isLoading)
        } header: {
            Text(Constants.iconHeader)
        }
    }

    private func suggestedIconCell(_ emoji: String) -> some View {
        let isSelected = emoji == selectedIcon

        return Button {
            viewModel.icon = emoji
        } label: {
            iconCell(isHighlighted: isSelected) {
                Text(emoji)
                    .font(.system(size: Constants.iconCellFontSize))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(emoji)
        .accessibilityValue(isSelected ? Constants.selectedValue : Constants.unselectedValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 이모지 키보드를 여는 칸. 입력은 뒤에 숨긴 칸이 받고, 이 칸은 포커스만 옮긴다 — 이모지
    /// 한 글자를 받는 칸을 그대로 드러내면 커서·선택 핸들이 아이콘을 가린다.
    private var customIconCell: some View {
        ZStack {
            iconField

            Button {
                isIconFocused = true
            } label: {
                iconCell(isHighlighted: isCustomIconSelected || isIconFocused) {
                    customIconLabel
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Constants.customIconLabel)
            .accessibilityValue(
                isCustomIconSelected ? selectedIcon : Constants.unselectedValue
            )
            .accessibilityHint(Constants.customIconHint)
            .accessibilityAddTraits(isCustomIconSelected ? .isSelected : [])
        }
    }

    @ViewBuilder
    private var customIconLabel: some View {
        if isCustomIconSelected {
            Text(selectedIcon)
                .font(.system(size: Constants.iconCellFontSize))
        } else {
            Image(systemName: Constants.customIconImage)
                .imageScale(.large)
                .foregroundStyle(Color.grey500)
        }
    }

    private var iconField: some View {
        TextField("", text: $iconDraft)
            .focused($isIconFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .frame(width: Constants.iconCellSize, height: Constants.iconCellSize)
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

    private func iconCell<Content: View>(
        isHighlighted: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: Constants.iconCellSize, height: Constants.iconCellSize)
            .background(Color.grey100, in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(
                        isHighlighted ? Color.indigo500 : .clear,
                        lineWidth: Constants.selectionBorderWidth
                    )
            }
            .contentShape(.circle)
    }

    // MARK: - Classification Section

    /// 분류 카드와, 그 결과를 손으로 덮어쓰는 카테고리 행.
    private var classificationSection: some View {
        Section {
            ThreadClassificationCard(viewModel: viewModel, mode: classificationMode)

            if showsCategoryRow {
                categoryRow
            }
        } header: {
            Text(Constants.classificationHeader)
        }
    }

    private var categoryRow: some View {
        Button {
            viewModel.isCategorySheetPresented = true
        } label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(Constants.categoryLabel)
                    .appFont(.body, color: Color.grey900)

                Spacer(minLength: 0)

                Text(viewModel.category.displayName)
                    .appFont(.callout, color: Color.grey500)

                Image(systemName: Constants.categoryImage)
                    .foregroundStyle(Color.grey500)
            }
        }
        // 분류가 끝나면 결과가 카테고리를 덮어쓰므로, 그 사이에 고른 값은 사라진다.
        .disabled(viewModel.classification.isLoading)
        .accessibilityLabel(Constants.categoryLabel)
        .accessibilityValue(viewModel.category.displayName)
        .accessibilityHint(Constants.categoryHint)
    }
}
