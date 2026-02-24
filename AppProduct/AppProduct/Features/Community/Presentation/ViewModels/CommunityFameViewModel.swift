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
    
    private let useCaseProvider: CommunityUseCaseProviding
    
    var selectedWeek: Int = 1
    var selectedUniversity: String = "전체"
    var selectedPart: UMCPartType? = nil  // nil = "전체"

    private(set) var fameItems: Loadable<[CommunityFameItemModel]> = .idle
    private(set) var hasLoadedInitialData: Bool = false
    private(set) var schoolOptions: [String] = []

    // MARK: -  Computed Properties

    var availableWeeks: [Int] {
        Array(1...12)
    }

    var availableUniversities: [String] {
        if !schoolOptions.isEmpty {
            return schoolOptions
        }

        guard case .loaded(let items) = fameItems else { return [] }
        let universities = Set(items.map(\.university))
        return universities.sorted()
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
                let matchPart = selectedPart == nil ? true : item.part == selectedPart
                
                return matchWeek && matchUniversity && matchPart
            }
            
            // 필터링 결과 그룹화
            let grouped = Dictionary(grouping: filtered, by: { $0.university })
            
            return grouped.map { (university: $0.key, items: $0.value) }
                .sorted { $0.university < $1.university }
        }
    
    // MARK: - Init
    
    init(container: DIContainer) {
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
    }

    // MARK: - Function

    @MainActor
    func loadInitialDataIfNeeded() async {
        guard !hasLoadedInitialData else { return }

        async let schoolsTask: Void = fetchSchools()
        async let trophiesTask: Void = fetchFameItems(query: currentFilterQuery())
        _ = await (schoolsTask, trophiesTask)

        hasLoadedInitialData = true
    }
    
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

    @MainActor
    func fetchFameItemsForCurrentFilter() async {
        await fetchFameItems(query: currentFilterQuery())
    }

    // MARK: - Private

    @MainActor
    private func fetchSchools() async {
        do {
            schoolOptions = try await useCaseProvider.fetchCommunitySchoolsUseCase.execute()
            if selectedUniversity != "전체",
               !schoolOptions.contains(selectedUniversity) {
                selectedUniversity = "전체"
            }
        } catch {
            // 학교 목록 조회 실패 시 기존 데이터(또는 명예의 전당 응답 유추값) 사용
        }
    }

    private func currentFilterQuery() -> TrophyListQuery {
        TrophyListQuery(
            week: selectedWeek,
            school: normalizedSchoolQuery,
            part: selectedPart?.apiValue
        )
    }

    private var normalizedSchoolQuery: String? {
        let trimmed = selectedUniversity.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "전체" {
            return nil
        }
        return trimmed
    }
}
