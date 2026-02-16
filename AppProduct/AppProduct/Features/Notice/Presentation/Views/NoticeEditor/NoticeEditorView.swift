//
//  NoticeEditorView.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import SwiftUI
import PhotosUI

/// 공지사항 작성/수정 에디터 화면
///
/// 카테고리 선택, 제목/본문 입력, 이미지/링크/투표 첨부 기능을 제공합니다.
struct NoticeEditorView: View {

    // MARK: - Property
    private let container: DIContainer
    @AppStorage(AppStorageKey.organizationType) private var organizationType: String = ""
    @AppStorage(AppStorageKey.chapterName) private var chapterName: String = ""
    @AppStorage(AppStorageKey.schoolName) private var schoolName: String = ""
    @State private var viewModel: NoticeEditorViewModel
    @State private var newlyAddedLinkID: UUID?
    @FocusState private var isTitleFieldFocused: Bool
    @FocusState private var isContentFieldFocused: Bool

    // MARK: - Initializer
    init(container: DIContainer, userPart: UMCPartType?, mode: NoticeEditorMode = .create) {
        self.container = container

        let noticeUseCase = container.resolve(NoticeUseCaseProtocol.self)
        let storageUseCase = container.resolve(NoticeStorageUseCaseProtocol.self)

        _viewModel = State(initialValue: NoticeEditorViewModel(
            noticeUseCase: noticeUseCase,
            storageUseCase: storageUseCase,
            userPart: userPart,
            mode: mode
        ))
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let chipSpacing: CGFloat = 8
        static let toolBtnIconSize: CGFloat = 20
        static let toolBtnFrame: CGSize = .init(width: 30, height: 30)
        static let alarmSize: CGFloat = 16
        static let alarmPadding: EdgeInsets = .init(top: 9, leading: .zero, bottom: 9, trailing: .zero)
        static let alarmWidth: CGFloat = 110
        static let targetSheetLargeDetentFraction: CGFloat = 0.85
        static let targetSheetSmallDetentFraction: CGFloat = 0.38
        static let contentBottomInset: CGFloat = 140
        static let linkScrollDelayNanos: UInt64 = 120_000_000
    }

    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: DefaultSpacing.spacing16) {
                    textfieldSection
                        
                    if !viewModel.noticeImages.isEmpty {
                        imageSection
                    }
                    if !viewModel.noticeLinks.isEmpty {
                        linkSection
                    }
                    if viewModel.isVoteConfirmed {
                        voteSection
                    }
                }
                .padding(.bottom, Constants.contentBottomInset)
            }
            .onChange(of: viewModel.noticeLinks.count) { oldValue, newValue in
                guard newValue > oldValue, let targetID = newlyAddedLinkID else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(targetID, anchor: .bottom)
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: Constants.linkScrollDelayNanos)
                    newlyAddedLinkID = nil
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationSubtitle(navigationSubtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            viewModel.applyOrganizationType(organizationType)
        }
        .safeAreaBar(edge: .top) {
            if viewModel.selectedCategory.hasSubCategories && !viewModel.isEditMode {
                subCategorySection
            }
        }
        .sheet(item: $viewModel.activeSheetType) { sheetType in
            TargetSheetView(viewModel: viewModel, sheetType: sheetType)
                .presentationDetents(targetSheetDetents(for: sheetType))
                .presentationDragIndicator(.visible)
        }
        .safeAreaBar(edge: .bottom, alignment: .leading) {
            HStack {
                GlassEffectContainer {
                    HStack {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItems,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: Constants.toolBtnIconSize))
                                .foregroundStyle(.black)
                                .frame(width: Constants.toolBtnFrame.width, height: Constants.toolBtnFrame.height)
                                .padding(DefaultConstant.defaultBtnPadding)
                        }
                        
                        ToolBtn(icon: "link", action: {
                            let newItem = NoticeLinkItem()
                            viewModel.noticeLinks.append(newItem)
                            newlyAddedLinkID = newItem.id
                        })
                        
                        if !viewModel.isEditMode {
                            ToolBtn(icon: "chart.bar.fill", action: {
                                viewModel.showVotingFormSheet()
                            })
                        }
                    }
                }
                .glassEffect()
                Spacer()
                if !viewModel.isEditMode {
                    alarmToggle
                        .glassEffect()
                }
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.bottom, DefaultSpacing.spacing16)
        }
        .onChange(of: viewModel.selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                await viewModel.loadSelectedImages()
            }
        }
        .onChange(of: organizationType) { _, newValue in
            viewModel.applyOrganizationType(newValue)
        }
        .fullScreenCover(isPresented: $viewModel.showVoting) {
            VotingFormSheetView(
                formData: $viewModel.voteFormData,
                onCancel: {
                    viewModel.cancelVotingEdit()
                },
                onConfirm: {
                    viewModel.confirmVote()
                },
                mode: viewModel.isVoteConfirmed ? .edit : .create
            )
        }
        .alertPrompt(item: $viewModel.alertPrompt)
    }

    private var subCategorySection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            HStack(alignment: .center) {
                Text("게시판 분류")
                    .appFont(.calloutEmphasis)
                Text("중복 선택 가능")
                    .appFont(.footnote, color: .grey400)
            }
            
            HStack(spacing: Constants.chipSpacing) {
                ForEach(viewModel.selectedCategory.subCategories) { subCategory in
                    ChipButton(
                        subCategory.labelText,
                        isSelected: viewModel.isSubCategoryHighlighted(subCategory),
                        trailingIcon: subCategory.hasFilter ? true : nil
                    ) {
                        if subCategory.hasFilter {
                            viewModel.selectSubCategoryIfNeeded(subCategory)
                            viewModel.openSheet(for: subCategory)
                        } else {
                            viewModel.toggleSubCategory(subCategory)
                        }
                    }
                    .buttonSize(.medium)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    // MARK: - safeAreaBar ToolBtn
    /// 링크, 투표 추가
    private func ToolBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Constants.toolBtnIconSize))
                .foregroundStyle(.black)
                .frame(width: Constants.toolBtnFrame.width, height: Constants.toolBtnFrame.height)
                .padding(DefaultConstant.defaultBtnPadding)
        }
    }
    
    // MARK: - textfieldSection
    private var textfieldSection: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ArticleTextField(
                placeholder: .title,
                text: $viewModel.title,
                focused: $isTitleFieldFocused,
                submitLabel: .next,
                onSubmit: {
                    isContentFieldFocused = true
                }
            )
            
            Divider()
            
            ArticleTextField(
                placeholder: .content,
                text: $viewModel.content,
                focused: $isContentFieldFocused
            )
                .frame(minHeight: 200, alignment: .top)
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .padding(.top, DefaultSpacing.spacing24)
        .padding(.bottom, DefaultSpacing.spacing32)
    }
    
    // MARK: - imageSection
    private var imageSection: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(viewModel.noticeImages, id: \.id) { item in
                    ImageAttachmentCard(
                        id: item.id,
                        imageData: item.imageData,
                        isLoading: item.isLoading,
                        onDismiss: {
                            viewModel.removeImage(item)
                        }
                    )
                }
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - linkSection
    private var linkSection: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            ForEach($viewModel.noticeLinks, id: \.id) { $item in
                LinkAttachmentCard(
                    link: $item.link,
                    shouldAutoFocus: $item.wrappedValue.id == newlyAddedLinkID,
                    onDismiss: {
                        viewModel.removeLink($item.wrappedValue)
                    }
                )
                .id($item.wrappedValue.id)
            }
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    // MARK: - voteSection
    private var voteSection: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Group {
                if viewModel.isEditMode {
                    // 수정 모드: 읽기 전용 (삭제만 가능)
                    VoteAttachmentCard(
                        formData: $viewModel.voteFormData,
                        mode: .readonly,
                        onDelete: {
                            viewModel.deleteVote()
                        }
                    )
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                } else {
                    VoteAttachmentCard(
                        formData: $viewModel.voteFormData,
                        mode: .editable,
                        onDelete: {
                            viewModel.deleteVote()
                        },
                        onEdit: {
                            viewModel.editVote()
                        }
                    )
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                }
            }
            
            Label("글 게시 후 투표는 수정이 불가능해요.", systemImage: "exclamationmark.circle")
                .foregroundStyle(.grey500)
                .appFont(.footnote)
        }
    }
    
    // MARK: - alarmToggle
    private var alarmToggle: some View {
        Toggle(isOn: $viewModel.allowAlert, label: {
            Label(
                viewModel.allowAlert ? "알림 발송" : "알림 미발송",
                systemImage: viewModel.allowAlert ? "bell.fill" : "bell.slash.fill"
            )
            .frame(width: Constants.alarmWidth)
            .padding(Constants.alarmPadding)
        })
        .appFont(.body, weight: .medium)
        .toggleStyle(.button)
        .tint(.indigo500)
    }
    
    // MARK: - Toolbar
    /// 공지 생성 화면 상단 툴바 (ToolbarTitleMenu 기반 카테고리 메뉴)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !viewModel.isEditMode {
            ToolBarCollection.ToolBarCenterMenu(
                items: viewModel.availableCategories,
                selection: categoryBinding,
                itemLabel: { $0.labelText },
                itemIcon: { $0.labelIcon }
            )
        }

        ToolBarCollection.ConfirmBtn(action: {
            Task {
                await viewModel.saveNotice()
            }
        }, disable: !viewModel.canSubmit)
    }

    private var navigationTitle: String {
        if viewModel.isEditMode {
            return "공지 수정"
        }
        return viewModel.selectedCategory.labelText
    }

    /// 메인 카테고리가 지부/학교일 때 본인 소속명을 서브타이틀로 노출합니다.
    private var navigationSubtitle: String {
        switch viewModel.selectedCategory {
        case .branch:
            let trimmedChapter = chapterName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedChapter.isEmpty ? "지부" : trimmedChapter
        case .school:
            let trimmedSchool = schoolName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedSchool.isEmpty ? "학교" : trimmedSchool
        case .central, .part:
            return ""
        }
    }

    private var categoryBinding: Binding<EditorMainCategory> {
        Binding(
            get: { viewModel.selectedCategory },
            set: { viewModel.selectCategory($0) }
        )
    }

    private func targetSheetDetents(for sheetType: TargetSheetType) -> Set<PresentationDetent> {
        switch sheetType {
        case .part, .branch:
            return [.fraction(Constants.targetSheetSmallDetentFraction)]
        case .school:
            return [.fraction(Constants.targetSheetLargeDetentFraction)]
        }
    }
}
