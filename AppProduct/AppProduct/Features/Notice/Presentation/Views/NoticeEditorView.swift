//
//  NoticeEditorView.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import SwiftUI
import PhotosUI

struct NoticeEditorView: View {

    // MARK: - Property
    @State private var viewModel: NoticeEditorViewModel

    // MARK: - Initializer
    init(userPart: Part? = nil) {
        _viewModel = State(initialValue: NoticeEditorViewModel(userPart: userPart))
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let chipSpacing: CGFloat = 8
        static let toolBtnIconSize: CGFloat = 20
        static let toolBtnFrame: CGSize = .init(width: 30, height: 30)
    }

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                NoticeTextField()
//                if !viewModel.noticeImages.isEmpty {
//                    
//                }
            }
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolBarCollection.TopBarCenterMenu (
                icon: viewModel.selectedCategory.labelIcon,
                title: viewModel.selectedCategory.labelText,
                items: viewModel.availableCategories,
                selection: categoryBinding,
                itemLabel: { $0.labelText },
                itemIcon: { $0.labelIcon }
            )
        }
        .safeAreaBar(edge: .top) {
            if viewModel.selectedCategory.hasSubCategories {
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
//                PhotosPicker(
//                    selection: $viewModel.selectedPhotoItem,
//                    matching: .images
//                ) {
//                    Image(systemName: "photo.fill")
//                        .font(.system(size: Constants.toolBtnIconSize))
//                        .foregroundStyle(.black)
//                        .frame(width: Constants.toolBtnFrame.width, height: Constants.toolBtnFrame.height)
//                        .padding(DefaultConstant.defaultBtnPadding)
//                        .glassEffect()
//                }
                ToolBtn(icon: "link", action: {
                    
                })
                ToolBtn(icon: "chart.bar.fill", action: {
                    
                })
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.bottom, DefaultConstant.defaultContentBottomMargins)
        }
//        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
//            Task {
//                await viewModel.loadSelectedImage()
//            }
//        }
    }

    private var subCategorySection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            HStack(alignment: .bottom) {
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
                .glassEffect()
        }
    }
    
    // MARK: - imageSection
//    private var imageSection: some View {
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(viewModel.noticeImages, id: \.id) { item in
//                    AttachedImageCard(
//                        id: item.id,
//                        imageData: item.imageData,
//                        onDismiss: {
//                            viewModel.removeImage(item)
//                        }
//                    )
//                }
//            }
//        }
//    }
    
    // MARK: - Computed Property
    private var categoryBinding: Binding<EditorMainCategory> {
        Binding(
            get: { viewModel.selectedCategory },
            set: { viewModel.selectCategory($0) }
        )
    }
}

private struct NoticeTextField: View {
    
    @State private var title: String = ""
    @State private var content: String = ""
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ArticleTextField(placeholder: .title, text: $title)
            
            Divider()
            
            ArticleTextField(placeholder: .content, text: $content)
        }
        .padding(.top, DefaultSpacing.spacing24)
    }
}

// MARK: - Preview
#Preview("iOS 파트장의 화면") {
    NavigationStack {
        NoticeEditorView(userPart: .ios)
    }
}

#Preview("파트장이 아닌 운영진의 화면") {
    NavigationStack {
        NoticeEditorView(userPart: nil)
    }
}
