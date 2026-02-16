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
    @AppStorage(AppStorageKey.schoolName) private var schoolName: String = ""
    @AppStorage(AppStorageKey.chapterName) private var chapterName: String = ""
    @AppStorage(AppStorageKey.responsiblePart) private var responsiblePart: String = ""
    @AppStorage(AppStorageKey.organizationType) private var organizationType: String = ""
    @AppStorage(AppStorageKey.chapterId) private var chapterId: Int = 0
    @AppStorage(AppStorageKey.schoolId) private var schoolId: Int = 0
    @State private var viewModel: NoticeViewModel
    @State private var search: String = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var isRetryingNotices: Bool = false
    
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
    /// 화면 내 반복되는 문구/수치를 한 곳에서 관리합니다.
    private enum Constants {
        /// 검색창 placeholder
        static let searchPlaceholder: String = "제목, 내용 검색"
        /// 초기/재로딩 상태 안내 문구
        static let loadingMessage: String = "공지를 불러오고 있어요"
        /// 빈 공지 상태 문구
        static let emptyTitle: String = "아직 등록된 공지사항이 없어요"
        static let emptySystemImage: String = "exclamationmark.triangle.text.page"
        static let emptyDescription: String = "운영진이 공지사항을 등록하면 이곳에 표시됩니다"
        /// 실패 상태 문구
        static let failedTitle: String = "불러오지 못했어요"
        static let failedSystemImage: String = "exclamationmark.triangle"
        static let failedDescription: String = "공지사항을 불러오지 못했습니다. 잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
        /// 무한 스크롤 추가 로딩 인디케이터 하단 여백
        static let loadingMoreBottomPadding: CGFloat = DefaultSpacing.spacing16
        /// 사용자 컨텍스트 변경 감지용 signature 구분자
        static let userContextSeparator: String = "|"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: noticePathBinding) {
            content
            .searchable(text: $search, prompt: Constants.searchPlaceholder)
            .searchToolbarBehavior(.minimize)
            .navigationTitle(viewModel.selectedMainFilter.labelText)
            .onChange(of: search) { _, newValue in
                handleSearchChanged(newValue)
            }
            .onSubmit(of: .search, submitSearch)
            .toolbar { toolbarContent }
            .safeAreaBar(edge: .top) { topSafeAreaContent }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavigationDestination.self, destination: navigationDestinationView)
            .task {
                applyUserContext()
                syncNoticeEditorGisuId()
                #if DEBUG
                if let debugState = NoticeDebugState.fromLaunchArgument() {
                    debugState.apply(to: viewModel)
                    return
                }
                #endif
                viewModel.fetchGisuList()
            }
            .onChange(of: viewModel.selectedGeneration) { _, _ in
                syncNoticeEditorGisuId()
            }
            .onChange(of: userContextSignature) { _, _ in
                applyUserContext()
            }
            .onDisappear {
                searchTask?.cancel()
            }
            .background(.white)
        }
    }

    // MARK: - Content Rendering
    /// Loadable 상태에 따라 본문을 분기 렌더링합니다.
    @ViewBuilder
    private var content: some View {
        switch viewModel.noticeItems {
        case .idle, .loading:
            Progress(message: Constants.loadingMessage)
        case .loaded(let noticeItem):
            noticeContent(noticeItem)
        case .failed:
            failedContent()
        }
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
            noticeRow(item)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(DefaultConstant.defaultListPadding)
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom, Constants.loadingMoreBottomPadding)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    
    /// Failed - 데이터 로드 실패
    private func failedContent() -> some View {
        RetryContentUnavailableView(
            title: Constants.failedTitle,
            systemImage: Constants.failedSystemImage,
            description: Constants.failedDescription,
            retryTitle: Constants.retryTitle,
            isRetrying: isRetryingNotices,
            minRetryButtonWidth: Constants.retryMinimumWidth,
            minRetryButtonHeight: Constants.retryMinimumHeight
        ) {
            await retryNotices()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    /// Loaded - 데이터가 없을 때
    private var unavailableContent: some View {
        ContentUnavailableView(
            Constants.emptyTitle,
            systemImage: Constants.emptySystemImage,
            description: Text(Constants.emptyDescription)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }


    // MARK: - Retry
    @MainActor
    private func retryNotices() async {
        guard !isRetryingNotices else { return }
        isRetryingNotices = true
        defer { isRetryingNotices = false }
        await viewModel.retryCurrentRequest()
    }

    // MARK: - Search
    /// 검색어를 비웠을 때만 검색 모드를 해제합니다.
    private func handleSearchChanged(_ newValue: String) {
        // 실시간 검색 비활성화:
        // 검색 API는 onSubmit(.search)에서만 호출합니다.
        guard newValue.isEmpty else { return }
        searchTask?.cancel()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            await viewModel.clearSearch()
        }
    }

    /// 검색 submit 시에만 API를 호출합니다.
    private func submitSearch() {
        searchTask?.cancel()
        let keyword = search.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask = Task {
            guard !Task.isCancelled else { return }
            if keyword.isEmpty {
                await viewModel.clearSearch()
            } else {
                await viewModel.searchNotices(keyword: keyword)
            }
        }
    }

    // MARK: - Row
    /// 공지 셀 탭/무한스크롤 트리거를 묶은 row 구성입니다.
    private func noticeRow(_ item: NoticeItemModel) -> some View {
        NoticeItem(model: item) {
            let noticeDetail = item.toNoticeDetail()
            pathStore.noticePath.append(.notice(.detail(detailItem: noticeDetail)))
        }
        .task(id: item.id) {
            await viewModel.loadNextPageIfNeeded(currentItem: item)
        }
    }

    // MARK: - User Context
    /// AppStorage 사용자 컨텍스트를 ViewModel 필터 라벨에 반영합니다.
    private func applyUserContext() {
        viewModel.applyUserContext(
            schoolName: schoolName,
            chapterName: chapterName,
            responsiblePart: responsiblePart,
            organizationTypeRawValue: organizationType,
            chapterId: chapterId,
            schoolId: schoolId
        )
    }

    /// 공지 생성 진입에 사용할 현재 선택 기수 ID를 PathStore에 동기화합니다.
    private func syncNoticeEditorGisuId() {
        pathStore.noticeEditorSelectedGisuId = viewModel.selectedGisuIdForEditor
    }

    /// 사용자 컨텍스트 변경 감지를 위한 서명 문자열입니다.
    private var userContextSignature: String {
        [schoolName, chapterName, responsiblePart, organizationType, String(chapterId), String(schoolId)]
            .joined(separator: Constants.userContextSeparator)
    }
    
    // MARK: - Bindings
    /// 기수 선택 바인딩
    private var generationBinding: Binding<Generation> {
        Binding(
            get: { viewModel.selectedGeneration },
            set: { viewModel.selectGeneration($0) }
        )
    }

    /// 현재 탭의 Notice NavigationPath 바인딩입니다.
    private var noticePathBinding: Binding<[NavigationDestination]> {
        Binding(
            get: { pathStore.noticePath },
            set: { newValue in
                // NavigationStack이 동일 경로를 다시 쓰는 경우를 무시해
                // "tried to update multiple times per frame" 경고를 줄입니다.
                guard pathStore.noticePath != newValue else { return }
                pathStore.noticePath = newValue
            }
        )
    }

    // MARK: - Toolbar / Navigation Builders
    /// 상단 툴바(기수 + 메인 필터)를 구성합니다.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolBarCollection.ToolBarCenterMenu(
            items: viewModel.mainFilterItems,
            selection: mainFilterBinding,
            itemLabel: { $0.labelText },
            itemIcon: { $0.labelIcon },
            onSelect: { selected in
                #if DEBUG
                print("[Notice][MainFilter] tapped: \(selected.labelText)")
                #endif
            }
        )

        ToolBarCollection.GenerationFilter(
            title: viewModel.selectedGeneration.title,
            generations: viewModel.generations,
            selection: generationBinding
        )
    }

    /// 메인필터 선택 바인딩
    private var mainFilterBinding: Binding<NoticeMainFilterType> {
        Binding(
            get: { viewModel.selectedMainFilter },
            set: { viewModel.selectMainFilter($0) }
        )
    }

    /// 메인 필터 타입에 따라 노출되는 서브필터 영역입니다.
    @ViewBuilder
    private var topSafeAreaContent: some View {
        if viewModel.showSubFilter {
            NoticeSubFilter(viewModel: viewModel)
        }
    }

    /// Notice 탭 내 destination 라우팅 뷰입니다.
    private func navigationDestinationView(_ destination: NavigationDestination) -> some View {
        NavigationRoutingView(destination: destination)
    }

}
