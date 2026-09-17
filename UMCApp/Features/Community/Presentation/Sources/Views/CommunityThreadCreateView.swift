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

    static let titleLabel = "스레드 제목"
    static let descriptionLabel = "스레드 특징"
    static let descriptionHint = "어떤 스레드인지 한 줄로 알려 주세요."
    static let iconLabel = "스레드 아이콘"
    static let iconHint = "이모지 키보드에서 이모지 하나를 고르세요. 비워 두면 카테고리 기본 이모지를 씁니다."
    static let categoryLabel = "카테고리"
    static let categoryHint = "탭하면 카테고리를 고를 수 있어요."

    static let inviteeLabel = "초대할 챌린저"
    static let inviteeEmptyValue = "선택 안 함"
    static let inviteeHint = "탭하면 초대할 챌린저를 고를 수 있어요."

    static let categoryImage = "chevron.up.chevron.down"
    static let inviteeImage = "chevron.right"
    static let errorImage = "exclamationmark.triangle"

    /// 이모지 한 칸이 아이콘처럼 보이도록 제목보다 크게 잡는다.
    static let iconFontSize: CGFloat = 28
    /// 제목 옆 원형 슬롯 지름. 이모지 둘레에 여백이 남도록 글자 크기보다 넉넉히 잡는다.
    static let iconSlotSize: CGFloat = 52
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

    /// 아이콘 슬롯 탭과 "이모지 변경하기" 가 이모지 키보드를 바로 띄우게 하는 통로.
    @FocusState private var isIconFocused: Bool

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
        Form {
            submitErrorSection

            composerSection

            classificationSection

            inviteeSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { submitButton }
        // 작성 중 다른 탭으로 넘어가면 초안을 잃는다 — 스레드 방 화면과 같이 탭 바를 숨긴다.
        .toolbarVisibility(.hidden, for: .tabBar)
        .sheet(isPresented: $viewModel.isCategorySheetPresented) {
            ThreadCategorySheet(
                selection: $viewModel.category,
                recommended: viewModel.recommendedCategory
            )
        }
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

    /// 제출 실패 메시지. 일정 등록 화면처럼 폼 맨 위 섹션에 띄워 입력부보다 먼저 읽히게 한다.
    @ViewBuilder
    private var submitErrorSection: some View {
        if let message = viewModel.submitErrorMessage {
            Section {
                errorLabel(message)
            }
        }
    }

    /// 아이콘·제목과 특징을 한 섹션으로 묶은 입력부. 두 행 사이 구분선은 Form 이 그린다.
    private var composerSection: some View {
        Section {
            HStack(spacing: DefaultSpacing.spacing12) {
                iconSlot

                ArticleTextField(
                    placeholder: .threadTitle,
                    text: $viewModel.title,
                    focused: $isTitleFocused,
                    submitLabel: .next,
                    onSubmit: { isDescriptionFocused = true }
                )
                .accessibilityLabel(Constants.titleLabel)
            }

            ArticleTextField(
                placeholder: .threadDescription,
                text: $viewModel.threadDescription,
                focused: $isDescriptionFocused
            )
            .accessibilityLabel(Constants.descriptionLabel)
            .accessibilityHint(Constants.descriptionHint)
        }
    }

    /// 제목 옆 원형 이모지 슬롯. 비어 있으면 카테고리 기본 이모지를 흐리게 띄우고, 분류 결과와
    /// 손으로 고른 이모지가 모두 이 한 칸에 보인다.
    ///
    /// 이모지 한 글자보다 슬롯이 커서 글자 밖을 눌러도 키보드가 뜨도록 탭을 슬롯 전체로 넓힌다.
    private var iconSlot: some View {
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
        .frame(width: Constants.iconSlotSize, height: Constants.iconSlotSize)
        .background(Color.grey100, in: .circle)
        .contentShape(.circle)
        .onTapGesture { isIconFocused = true }
        .accessibilityLabel(Constants.iconLabel)
        .accessibilityHint(Constants.iconHint)
    }

    /// 입력부 바로 아래 섹션의 분류 카드. 카테고리 선택 행은 자동 분류로 해결되지 않는 상태에서만
    /// 따라 나온다. 카드 표면은 Form 셀이 맡으므로 카드 자체 표면은 끈다.
    private var classificationSection: some View {
        Section {
            ThreadClassificationCard(viewModel: viewModel, showsSurface: false) {
                isIconFocused = true
            }

            if viewModel.isManualSelectionVisible {
                categoryRow
            }
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
