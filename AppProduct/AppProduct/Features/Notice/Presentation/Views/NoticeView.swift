//
//  NoticeView.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import SwiftUI

// MARK: - NoticeView
struct NoticeView: View {
    // MARK: - Property
    @State var viewModel: NoticeViewModel
    @State private var search: String = ""

    // MARK: - Constants
    private enum Constants {
        static let listTopPadding: CGFloat = 10
        static let searchPlaceholder: String = "제목, 내용 검색"
    }

    // MARK: - Body
    var body: some View {
        List(viewModel.noticeItems) { item in
            NoticeItem(model: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(DefaultConstant.defaultListPadding)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GenerationMenuView(viewModel: viewModel)
            }
        }
        .safeAreaBar(edge: .top) {
            NoticeFilterView(viewModel: viewModel)
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .padding(.top, Constants.listTopPadding)
        }
        .searchable(text: $search, prompt: Constants.searchPlaceholder)
        .searchToolbarBehavior(.minimize)
        .sheet(isPresented: $viewModel.isShowingFilterSheet) {
            FilterSheetView(viewModel: viewModel)
        }
    }
}

// MARK: - GenerationMenuView
/// SRP: 기수 선택 메뉴만 담당
private struct GenerationMenuView: View {
    @Bindable var viewModel: NoticeViewModel

    private enum Constants {
        static let labelPadding: CGFloat = 6
    }

    var body: some View {
        Menu {
            generationPicker
            Divider()
            currentOnlyButton
        } label: {
            menuLabel
        }
    }

    // MARK: - Subviews
    private var generationPicker: some View {
        Picker("기수 선택", selection: selectedGenerationBinding) {
            ForEach(viewModel.generations) { generation in
                Text(generation.title).tag(generation as Generation?)
            }
        }
        .pickerStyle(.inline)
    }

    private var currentOnlyButton: some View {
        Button {
            viewModel.filterMode = .currentOnly
        } label: {
            HStack {
                Text("현재 기수만 보기")
                Spacer()
                if case .currentOnly = viewModel.filterMode {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private var menuLabel: some View {
        Text(viewModel.filterMode.label)
            .appFont(.footnote, weight: .bold)
            .padding(Constants.labelPadding)
    }

    // MARK: - Binding
    private var selectedGenerationBinding: Binding<Generation?> {
        Binding(
            get: {
                if case .generation(let gen) = viewModel.filterMode {
                    return gen
                }
                return nil
            },
            set: { newValue in
                if let generation = newValue {
                    viewModel.filterMode = .generation(generation)
                }
            }
        )
    }
}

// MARK: - NoticeFilterView
/// SRP: 공지 필터 칩 목록만 담당
/// OCP: 새로운 필터 타입은 filterItems 배열에 추가하면 됨
private struct NoticeFilterView: View {
    @State var viewModel: NoticeViewModel

    private enum Constants {
        static let hstackSpacing: CGFloat = 8
    }

    /// OCP: 필터 항목 데이터 - 새 필터 추가 시 여기만 수정
    private var filterItems: [NoticeFilterType] {
        [
            .all,
            .core,
            .branch(viewModel.userBranch),
            .school(viewModel.userSchool),
            .part(viewModel.userPart)
        ]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.hstackSpacing) {
                ForEach(filterItems) { filter in
                    filterChip(for: filter)
                }
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .padding(.horizontal, -DefaultConstant.defaultSafeHorizon)
    }

    // MARK: - Private Methods
    /// SRP: 단일 칩 버튼 생성 로직 분리
    @ViewBuilder
    private func filterChip(for filter: NoticeFilterType) -> some View {
        ChipButton(
            filter.labelText,
            isSelected: viewModel.selectedNoticeFilter == filter
        ) {
            viewModel.selectFilter(filter)
        }
        .buttonSize(.medium)
        .buttonStyle(.glassProminent)
    }
}

// MARK: - Preview Extension
extension NoticeViewModel {
    static let mock: NoticeViewModel = {
        let vm = NoticeViewModel()
        vm.configure(
            generations: (8...12).map { Generation(value: $0) },
            current: Generation(value: 12)
        )
        return vm
    }()
}

#Preview {
    NoticeView(viewModel: .mock)
}
