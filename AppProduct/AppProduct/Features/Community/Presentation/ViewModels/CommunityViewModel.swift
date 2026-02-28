//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    // MARK: - Property
    
    private let container: DIContainer
    private let useCaseProvider: CommunityUseCaseProviding

    var searchText: String = ""
    var selectedMenu: CommunityMenu = .all

    // 게시글 목록 상태
    private(set) var items: Loadable<[CommunityItemModel]> = .idle
    private(set) var isLoadingMore: Bool = false

    // 검색 결과 상태
    private(set) var searchState: Loadable<[CommunityItemModel]> = .idle
    private(set) var isSearchLoadingMore: Bool = false

    /// 게시글 목록 페이지네이션
    private var currentPage: Int = 0
    private var hasNext: Bool = true
    private let pageSize: Int = 10

    /// 검색 페이지네이션
    private var searchCurrentPage: Int = 0
    private var searchHasNext: Bool = true

    /// 디바운스용 Task
    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// View에서 사용할 현재 활성 상태 (검색 여부에 따라 전환)
    var contentState: Loadable<[CommunityItemModel]> {
        searchText.isEmpty ? items : searchState
    }

    /// View에서 사용할 현재 활성 로딩모어 상태
    var contentIsLoadingMore: Bool {
        searchText.isEmpty ? isLoadingMore : isSearchLoadingMore
    }

    var filteredItems: [CommunityItemModel] {
        if !searchText.isEmpty {
            guard case .loaded(let searchItems) = searchState else { return [] }
            return searchItems
        }

        guard case .loaded(let allItems) = items else { return [] }
        
        var filtered = allItems

        if selectedMenu != .all {
            switch selectedMenu {
            case .all: break
            case .party:
                filtered = filtered.filter { $0.category == .lighting }
            case .question:
                filtered = filtered.filter { $0.category == .question }
            case .information:
                filtered = filtered.filter { $0.category == .information }
            case .habit:
                filtered = filtered.filter { $0.category == .habit }
            case .free:
                filtered = filtered.filter { $0.category == .free }
            case .fame: break
            }
        }

        return filtered
    }
    
    // MARK: - Init
    
    init(container: DIContainer) {
        self.container = container
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
    }
    
    // MARK: - Function

    /// 초기 데이터 로드
    @MainActor
    func fetchInitialIfNeeded() async {
        if case .loaded = items {
            return
        }
        await fetchFirstPage()
    }

    /// 새로고침
    @MainActor
    func refresh() async {
        await fetchFirstPage()
    }

    /// 무한 스크롤 트리거 (검색/일반 자동 분기)
    @MainActor
    func loadMoreIfNeeded(currentItem: CommunityItemModel) async {
        if searchText.isEmpty {
            await loadMorePostsIfNeeded(currentItem: currentItem)
        } else {
            await loadMoreSearchIfNeeded(currentItem: currentItem)
        }
    }

    /// 검색어 변경 시 호출 (디바운스 적용)
    @MainActor
    func onSearchTextChanged() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            searchState = .idle
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, let self else { return }
            await self.fetchSearchFirstPage()
        }
    }

}

// MARK: - Private Function

private extension CommunityViewModel {
    @MainActor
    func fetchFirstPage() async {
        items = .loading
        currentPage = 0
        hasNext = true

        do {
            let query = PostListQuery(
                category: selectedMenu.toCategoryType(),
                page: 0,
                size: pageSize
            )

            let (fetchedItems, nextPageExists) = try await useCaseProvider.fetchCommunityItemsUseCase.execute(query: query)

            currentPage = 0
            hasNext = nextPageExists
            items = .loaded(fetchedItems)
        } catch let error as AppError {
            items = .failed(error)
        } catch {
            items = .failed(.unknown(message: error.localizedDescription))
        }
    }

    @MainActor
    func loadMorePostsIfNeeded(currentItem: CommunityItemModel) async {
        guard case .loaded(let allItems) = items,
              hasNext,
              !isLoadingMore,
              allItems.last?.id == currentItem.id else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let query = PostListQuery(
                category: selectedMenu.toCategoryType(),
                page: nextPage,
                size: pageSize
            )

            let (newItems, nextPageExists) = try await useCaseProvider.fetchCommunityItemsUseCase.execute(query: query)

            currentPage = nextPage
            hasNext = nextPageExists
            items = .loaded(allItems + newItems)
        } catch let error as AppError {
            items = .failed(error)
        } catch {
            items = .failed(.unknown(message: error.localizedDescription))
        }
    }

    @MainActor
    func fetchSearchFirstPage() async {
        searchState = .loading
        searchCurrentPage = 0
        searchHasNext = true

        do {
            let query = PostSearchQuery(keyword: searchText, page: 0, size: pageSize)
            let (fetchedItems, nextPageExists) = try await useCaseProvider.searchPostUseCase.execute(query: query)

            searchCurrentPage = 0
            searchHasNext = nextPageExists
            searchState = .loaded(fetchedItems)
        } catch let error as AppError {
            searchState = .failed(error)
        } catch {
            searchState = .failed(.unknown(message: error.localizedDescription))
        }
    }

    @MainActor
    func loadMoreSearchIfNeeded(currentItem: CommunityItemModel) async {
        guard case .loaded(let currentItems) = searchState,
              searchHasNext,
              !isSearchLoadingMore,
              currentItems.last?.id == currentItem.id else {
            return
        }

        isSearchLoadingMore = true
        defer { isSearchLoadingMore = false }

        do {
            let nextPage = searchCurrentPage + 1
            let query = PostSearchQuery(keyword: searchText, page: nextPage, size: pageSize)
            let (newItems, nextPageExists) = try await useCaseProvider.searchPostUseCase.execute(query: query)

            searchCurrentPage = nextPage
            searchHasNext = nextPageExists
            searchState = .loaded(currentItems + newItems)
        } catch let error as AppError {
            searchState = .failed(error)
        } catch {
            searchState = .failed(.unknown(message: error.localizedDescription))
        }
    }
}
