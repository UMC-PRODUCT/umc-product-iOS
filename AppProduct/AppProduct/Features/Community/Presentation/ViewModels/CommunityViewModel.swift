//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    // MARK: - Dependency
    
    private let fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol
    
    // MARK: - Property

    var searchText: String = ""
    var selectedMenu: CommunityMenu = .all

    private(set) var items: Loadable<[CommunityItemModel]> = .idle
    
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
                filtered = filtered.filter { $0.category == .impromptu }
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
    
    init(fetchCommunityItemsUseCase: FetchCommunityItemsUseCaseProtocol) {
        self.fetchCommunityItemsUseCase = fetchCommunityItemsUseCase
    }
    
    // MARK: - Function
    
    @MainActor
    func fetchCommunityItems() async {
        items = .loading
        do {
            let allItems = try await fetchCommunityItemsUseCase.execute()
            items = .loaded(allItems)
        } catch let error as DomainError {
            items = .failed(.domain(error))
        } catch {
            items = .failed(.unknown(message: error.localizedDescription))
        }
    }
}
