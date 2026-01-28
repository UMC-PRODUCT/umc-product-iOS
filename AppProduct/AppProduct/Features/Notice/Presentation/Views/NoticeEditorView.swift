//
//  NoticeEditorView.swift
//  AppProduct
//
//  Created by 이예지 on 1/24/26.
//

import SwiftUI

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
    }

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical) {
            NoticeTextField()
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
    }

    private var subCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                Text("게시판 분류")
                    .appFont(.subheadline, weight: .bold)
                Text("중복 선택 가능")
                    .appFont(.caption1, color: .grey400)
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
        VStack(spacing: 16) {
            ArticleTextField(placeholder: .title, text: $title)
            
            Divider()
            
            ArticleTextField(placeholder: .content, text: $content)
        }
        .padding(.top, 24)
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
