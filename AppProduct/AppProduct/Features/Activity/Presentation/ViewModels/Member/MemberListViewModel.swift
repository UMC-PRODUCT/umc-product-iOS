//
//  MemberListViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import SwiftUI

@Observable
final class MemberListViewModel {
    // MARK: - Dependency
    
    private let fetchMembersUseCase: FetchMembersUseCaseProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - State
    
    private(set) var membersState: Loadable<[MemberManagementItem]> = .idle
    var searchText: String = ""
    
    // MARK: - Init
    
    init(
        fetchMembersUseCase: FetchMembersUseCaseProtocol,
        errorHandler: ErrorHandler
    ) {
        self.fetchMembersUseCase = fetchMembersUseCase
        self.errorHandler = errorHandler
    }
    
    // MARK: - Computed Properties
    
    /// 검색어로 필터링된 멤버 목록
    private var filteredMembers: [MemberManagementItem] {
        guard case .loaded(let items) = membersState else {
            return []
        }
        
        if searchText.isEmpty {
            return items
        }
        
        return items.filter { member in
            member.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Part별로 그룹핑된 멤버 목록
    var groupedMembers: [(part: UMCPartType, members: [MemberManagementItem])] {
        let grouped = Dictionary(grouping: filteredMembers, by: { $0.part })
        return grouped
            .map { (part: $0.key, members: $0.value) }
            .sorted { $0.part.sortOrder < $1.part.sortOrder }
    }
    
    /// 검색 결과가 비어있는지 여부
    var isSearchResultEmpty: Bool {
        !searchText.isEmpty && filteredMembers.isEmpty
    }
    
    // MARK: - Action
    
    @MainActor
    func fetchMembers() async {
        membersState = .loading
        do {
            let members = try await fetchMembersUseCase.execute()
            membersState = .loaded(members)
        } catch let error as DomainError {
            membersState = .failed(.domain(error))
        } catch {
            errorHandler.handle(
                error,
                context: ErrorContext(
                    feature: "Activity",
                    action: "fetchMembers"
                )
            )
            membersState = .idle
        }
    }
}
