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
    @State private var viewModel: NoticeEditorViewModel

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
    }

    // MARK: - Body
    var body: some View {
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 수정 모드에서는 카테고리 변경 불가
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
        .safeAreaBar(edge: .top) {
            if viewModel.selectedCategory.hasSubCategories && !viewModel.isEditMode {
                subCategorySection
            }
        }
        .sheet(item: $viewModel.activeSheetType) { sheetType in
            TargetSheetView(viewModel: viewModel, sheetType: sheetType)
                .presentationDetents([.fraction(0.3)])
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
                            viewModel.noticeLinks.append(NoticeLinkItem())
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
                        isSelected: viewModel.isSubCategorySelected(subCategory),
                        trailingIcon: subCategory.hasFilter ? true : nil
                    ) {
                        viewModel.toggleSubCategory(subCategory)
                        if subCategory.hasFilter && viewModel.isSubCategorySelected(subCategory) {
                            viewModel.openSheet(for: subCategory)
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
            ArticleTextField(placeholder: .title, text: $viewModel.title)
            
            Divider()
            
            ArticleTextField(placeholder: .content, text: $viewModel.content)
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
                    onDismiss: {
                        viewModel.removeLink(item)
                    }
                )
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
    
    // MARK: - Computed Property
    private var categoryBinding: Binding<EditorMainCategory> {
        Binding(
            get: { viewModel.selectedCategory },
            set: { viewModel.selectCategory($0) }
        )
    }
}

//// MARK: - Preview
//#Preview("iOS 파트장의 화면") {
//    NavigationStack {
//        NoticeEditorView(userPart: .ios)
//    }
//}
//
//#Preview("파트장이 아닌 운영진의 화면") {
//    NavigationStack {
//        NoticeEditorView(userPart: nil)
//    }
//}
