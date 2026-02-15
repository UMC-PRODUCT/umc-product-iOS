//
//  NoticeView.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import SwiftUI

// MARK: - NoticeView
/// 공지사항 메인 화면
struct NoticeView: View {
    
    // MARK: - Properties
    @Environment(\.di) var di
    @Environment(ErrorHandler.self) var errorHandler
    @State private var viewModel: NoticeViewModel
    @State private var search: String = ""
    @State private var searchTask: Task<Void, Never>?
    
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }
    
    // MARK: - Initializer
    init(container: DIContainer) {
        _viewModel = State(
            initialValue: NoticeViewModel(container: container)
        )
    }
    
    // MARK: - Constants
    private enum Constants {
        static let listTopPadding: CGFloat = 10
        static let searchPlaceholder: String = "제목, 내용 검색"
        static let tintOpacity: Double = 0.5
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: Binding(
            get: { pathStore.noticePath },
            set: { pathStore.noticePath = $0 }
        )) {
            Group {
                switch viewModel.noticeItems {
                case .idle, .loading:
                          progressView
                case .loaded(let noticeItem):
                    noticeContent(noticeItem)
                case .failed(_):
                    Color.clear
                }
            }
            .searchable(text: $search, prompt: Constants.searchPlaceholder)
            .searchToolbarBehavior(.minimize)
            .onChange(of: search) { oldValue, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    guard !Task.isCancelled else { return }
                    if newValue.isEmpty {
                        await viewModel.clearSearch()
                    } else {
                        await viewModel.searchNotices(keyword: newValue)
                    }
                }
            }
            .toolbar {
                ToolBarCollection.GenerationFilter(
                    title: viewModel.selectedGeneration.title,
                    generations: viewModel.generations,
                    selection: generationBinding
                )
                ToolBarCollection.ToolBarCenterMenu(
                    items: viewModel.mainFilterItems,
                    selection: mainFilterBinding,
                    itemLabel: { $0.labelText },
                    itemIcon: { $0.labelIcon }
                )
            }
            .safeAreaBar(edge: .top) {
                if viewModel.showSubFilter {
                    NoticeSubFilter(viewModel: viewModel)
                        .equatable()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavigationDestination.self) { destination in
                NavigationRoutingView(destination: destination)
            }
            .task {
                viewModel.updateErrorHandler(errorHandler)
                viewModel.fetchGisuList()
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }
    
    /// loading
    private var progressView: some View {
        ProgressView(label: {
            Text("공지를 불러오고 있어요")
                .appFont(.callout)
        })
        .controlSize(.large)
        .tint(.indigo500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func noticeContent(_ data: [NoticeItemModel]) -> some View {
        if data.isEmpty {
            unavailableContent
        } else {
            availableContent(data)
        }
    }
    
    /// Loaded - 데이터가 있을 때
    private func availableContent(_ data: [NoticeItemModel]) -> some View {
        List(data) { item in
            NoticeItem(model: item) {
                let noticeDetail = item.toNoticeDetail()
                pathStore.noticePath.append(.notice(.detail(detailItem: noticeDetail)))
            }
            .onAppear {
                Task {
                    await viewModel.loadNextPageIfNeeded(currentItem: item)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(DefaultConstant.defaultListPadding)
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom, DefaultSpacing.spacing16)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    /// Loaded - 데이터가 없을 때
    private var unavailableContent: some View {
        ContentUnavailableView(
            "아직 등록된 공지사항이 없어요",
            systemImage: "exclamationmark.triangle.text.page",
            description: Text("운영진이 공지사항을 등록하면 이곳에 표시됩니다")
        )
        .tint(.indigo200.opacity(Constants.tintOpacity))
    }
    
    // MARK: - Computed Properties
    /// 기수 선택 바인딩
    private var generationBinding: Binding<Generation> {
        Binding(
            get: { viewModel.selectedGeneration },
            set: { viewModel.selectGeneration($0) }
        )
    }
    
    /// 메인필터 선택 바인딩
    private var mainFilterBinding: Binding<NoticeMainFilterType> {
        Binding(
            get: { viewModel.selectedMainFilter },
            set: { viewModel.selectMainFilter($0) }
        )
    }
}


  // MARK: - NoticeSubFilter
  /// 서브필터 영역 (전체, 운영진 공지 칩 + 파트 메뉴)
private struct NoticeSubFilter: View, Equatable {
    
    @Bindable var viewModel: NoticeViewModel  // = 제거
    
    static func == (lhs: NoticeSubFilter, rhs: NoticeSubFilter) -> Bool {
        lhs.viewModel.selectedSubFilter == rhs.viewModel.selectedSubFilter &&
        lhs.viewModel.selectedPart == rhs.viewModel.selectedPart
    }
    
    private enum Constants {
        static let hstackSpacing: CGFloat = 8
    }
    
    private var subFilterItems: [NoticeSubFilterType] {
        [.all, .staff]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.hstackSpacing) {
                ForEach(subFilterItems) { filter in
                    filterChip(for: filter)
                }
                PartFilterMenu(viewModel: viewModel)
                    .equatable()
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
    }
    
    /// 칩버튼 생성
    @ViewBuilder
    private func filterChip(for filter: NoticeSubFilterType) -> some View {
        ChipButton(
            filter.labelText,
            isSelected: viewModel.selectedSubFilter == filter
        ) {
            viewModel.selectSubFilter(filter)
        }
        .buttonSize(.medium)
    }
}

  // MARK: - PartFilterMenu
  /// 파트 선택 메뉴
private struct PartFilterMenu: View, Equatable {
    
    @Bindable var viewModel: NoticeViewModel  // = 제거
    
    static func == (lhs: PartFilterMenu, rhs: PartFilterMenu) -> Bool {
        lhs.viewModel.selectedPart == rhs.viewModel.selectedPart
    }
    
    private enum Constants {
        static let hstackSpacing: CGFloat = 4
        static let chevronSize: CGFloat = 10
        static let chipPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
    
    /// 파트 선택 바인딩
    private var partBinding: Binding<Part> {
        Binding(
            get: { viewModel.selectedPart },
            set: { viewModel.selectPart($0) }
        )
    }
    
    var body: some View {
        Menu {
            partPicker
        } label: {
            menuLabel
        }
    }
    
    /// 파트 Picker
    private var partPicker: some View {
        Picker("파트 선택", selection: partBinding) {
            ForEach(Part.allCases) { part in
                Text(part.name)
                    .tag(part)
            }
        }
        .pickerStyle(.inline)
    }
    
    /// 파트가 실제로 선택되었는지 (기본값 "파트"가 아닌 경우)
    private var isPartSelected: Bool {
        viewModel.selectedPart != .all
    }
    
    /// 메뉴 라벨
    private var menuLabel: some View {
        HStack(spacing: Constants.hstackSpacing) {
            Text(viewModel.selectedPart.name)
                .appFont(.subheadlineEmphasis)
            Image(systemName: "chevron.down")
                .font(.system(size: Constants.chevronSize))
        }
        .foregroundStyle(isPartSelected ? .grey000 : .grey600)
        .padding(Constants.chipPadding)
        .clipShape(Capsule())
        .background {
            Capsule()
                .fill(isPartSelected ? .indigo500 : .grey200)
        }
        .glassEffect(.clear.interactive(), in: Capsule())
    }
}
