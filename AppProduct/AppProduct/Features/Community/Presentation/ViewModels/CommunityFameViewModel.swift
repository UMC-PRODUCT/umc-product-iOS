//
//  CommunityFameViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/23/26.
//

import Foundation

@Observable
class CommunityFameViewModel {
    // MARK: - Properties
    
    private let container: DIContainer
    private let useCaseProvider: CommunityUseCaseProviding
    
    var selectedWeek: Int = 1
    var selectedUniversity: String = "전체"
    var selectedPart: String = "전체"

    private(set) var fameItems: Loadable<[CommunityFameItemModel]> = .idle

    // MARK: -  Computed Properties
    
    var availableWeeks: [Int] {
        guard case .loaded(let items) = fameItems else { return [1] }
        let weeks = Set(items.map { $0.week })
        return weeks.sorted()
    }
    
    var availableUniversities: [String] {
        guard case .loaded(let items) = fameItems else { return [] }
        let universities = Set(items.map(\.university))
        return universities.sorted()
    }
    
    var availableParts: [String] {
        guard case .loaded(let items) = fameItems else { return [] }
        let parts = Set(items.map(\.part.name))
        return parts.sorted()
    }

    var groupedByUniversity: [(university: String, items: [CommunityFameItemModel])] {
            guard case .loaded(let items) = fameItems else { return [] }
            
            // 주차/학교/파트 필터 적용
            let filtered = items.filter { item in
                let matchWeek = item.week == selectedWeek
                
                // 학교 필터
                let matchUniversity = (selectedUniversity == "전체" || selectedUniversity.isEmpty)
                                      ? true : item.university == selectedUniversity
                
                // 파트 필터
                let matchPart = (selectedPart == "전체" || selectedPart.isEmpty)
                ? true : item.part.name == selectedPart
                
                return matchWeek && matchUniversity && matchPart
            }
            
            // 필터링 결과 그룹화
            let grouped = Dictionary(grouping: filtered, by: { $0.university })
            
            return grouped.map { (university: $0.key, items: $0.value) }
                .sorted { $0.university < $1.university }
        }
    
    // MARK: - Init
    
    init(container: DIContainer) {
        self.container = container
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
    }

    // MARK: - Function
    
    @MainActor
    func fetchFameItems(query: TrophyListQuery) async {
        fameItems = .loading
        do {
            let items = try await useCaseProvider.fetchFameItemsUseCase.execute(query: query)
            fameItems = .loaded(items)
        } catch let error as AppError {
            fameItems = .failed(error)
        } catch {
            fameItems = .failed(.unknown(message: error.localizedDescription))
        }
    }

    func selectWeek(_ week: Int) {
        selectedWeek = week
    }
}
