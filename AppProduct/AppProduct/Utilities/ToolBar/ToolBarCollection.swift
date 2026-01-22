//
//  ToolBarCollection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import SwiftUI

struct ToolBarCollection {
    
    /// 일정 추가 버튼
    struct AddBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: "magnifyingglass")
                })
                .tint(tintColor)
            })
        }
    }
    
    /// 상단 알림 히스토리 버튼
    struct BellBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        let recentPush: Bool = false
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: recentPush ? "bell.badge" : "bell")
                })
                .tint(tintColor)
            })
        }
    }
    
    /// 상단 로고 툴바
    struct Logo: ToolbarContent {
        let image: ImageResource
        @Namespace var namespace
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading, content: {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 40)
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .disabled(true)
            })
            .sharedBackgroundVisibility(.hidden)
            .matchedTransitionSource(id: "logo", in: namespace)
        }
    }
    
    // MARK: - NoticeView
    /// 기수 필터
    struct GenerationFilter: ToolbarContent {
        
        @Bindable var viewModel: NoticeViewModel
        
        private enum Constants {
            static let labelPadding: CGFloat = 6
        }
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading, content: {
                Menu {
                    generationPicker
                } label: {
                    menuLabel
                }
            })
        }

        private var generationPicker: some View {
            Picker("기수 선택", selection: selectedGenerationBinding) {
                ForEach(viewModel.generations) { generation in
                    Text(generation.title).tag(generation as Generation?)
                }
            }
            .pickerStyle(.inline)
        }

        private var menuLabel: some View {
            Text(viewModel.selectedGeneration?.title ?? viewModel.currentGeneration?.title ?? "")
                .font(.callout)
                .fontWeight(.semibold)
        }

        private var selectedGenerationBinding: Binding<Generation?> {
            Binding(
                get: { viewModel.selectedGeneration },
                set: { newValue in
                    if let generation = newValue {
                        viewModel.selectedGeneration = generation
                    }
                }
            )
        }
    }
    
    // MARK: - NoticeFilter
    /// 메인 필터링 버튼(전체, 중앙운영사무국, 지부, 학교, 파트)
    struct NoticeMainFilter: ToolbarContent {

        @Bindable var viewModel: NoticeViewModel
        @Namespace var namespace

        private enum Constants {
            static let labelPadding: CGFloat = 6
        }

        /// 필터 항목 데이터
        private var mainFilterItems: [NoticeMainFilterType] {
            [
                .all,
                .central,
                .branch(viewModel.userBranch),
                .school(viewModel.userSchool),
                .part(viewModel.userPart)
            ]
        }

        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                Menu {
                    filterPicker
                } label: {
                    menuLabel
                }
            }
            .sharedBackgroundVisibility(.visible)
        }

        private var filterPicker: some View {
            Picker("필터 선택", selection: selectedFilterBinding) {
                ForEach(mainFilterItems) { filter in
                    Label(filter.labelText, systemImage: filter.labelIcon)
                        .tag(filter as NoticeMainFilterType?)
                }
            }
            .pickerStyle(.inline)
        }
        
        private var menuLabel: some View {
            HStack {
                Image(systemName: viewModel.selectedNoticeMainFilter.labelIcon)
                    .font(.system(size: 10))
                Spacer()
                Text(viewModel.selectedNoticeMainFilter.labelText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                chevronImage
            }
            .padding(10)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        
        private var chevronImage: some View {
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundStyle(.grey500)
        }

        private var selectedFilterBinding: Binding<NoticeMainFilterType?> {
            Binding(
                get: { viewModel.selectedNoticeMainFilter },
                set: { newValue in
                    if let filter = newValue {
                        viewModel.selectMainFilter(filter)
                    }
                }
            )
        }
    }
}
