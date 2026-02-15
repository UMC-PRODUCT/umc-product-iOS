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

    private(set) var items: Loadable<[CommunityItemModel]> = .idle
    
    /// 페이지네이션
    private(set) var currentPage: Int = 0
    private(set) var hasNext: Bool = true
    private(set) var isLoadingMore: Bool = false
    
    // MARK: - Computed Properties
    
    var filteredItems: [CommunityItemModel] {
        guard case .loaded(let allItems) = items else { return [] }
        
        var filtered = allItems
        
        // 메뉴
        if selectedMenu != .all {
            switch selectedMenu {
            case .all: break
            case .question:
                filtered = filtered.filter { $0.category == .question }
            case .party:
                filtered = filtered.filter { $0.category == .lighting }
            case .fame: break
            }
        }
        
        // 검색
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText)
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
    
    @MainActor
    func fetchCommunityItems(query: PostListQuery) async {
        items = .loading
        currentPage = 0
        hasNext = true
        
        do {
            let (fetchedItems, nextPageExists) = try await useCaseProvider.fetchCommunityItemsUseCase.execute(query: query)
            items = .loaded(fetchedItems)
            hasNext = nextPageExists
        } catch let error as AppError {
            items = .failed(error)
        } catch {
            items = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    @MainActor
    func loadMoreIfNeeded(currentItem: CommunityItemModel) async {
        guard case .loaded(let allItems) = items else { return }
        
        let thresholdIndex = allItems.index(allItems.endIndex, offsetBy: -5)
        guard let itemIndex = allItems.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex,
              !isLoadingMore,
              hasNext else { return }
        
        isLoadingMore = true
        
        let nextPage = currentPage + 1
        let query = PostListQuery(
            category: selectedMenu.toCategoryType(),
            page: nextPage,
            size: 10
        )
        
        do {
            let (newItems, nextPageExists) = try await useCaseProvider.fetchCommunityItemsUseCase.execute(query: query)

            guard case .loaded(var existingItems) = items else {
                isLoadingMore = false
                return
            }
            existingItems.append(contentsOf: newItems)
            items = .loaded(existingItems)
            currentPage = nextPage
            hasNext = nextPageExists
            isLoadingMore = false
        } catch {
            isLoadingMore = false
            print("[Community] pagination failed: \(error)")
        }
    }
}
